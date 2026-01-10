#!/bin/bash
# Script rápido para solucionar 404 del dashboard

echo "🔧 SOLUCIONANDO 404 DEL DASHBOARD (RÁPIDO)"
echo "=========================================="
echo ""

# Buscar servicio
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i dashboard | grep -v proxy | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Servicio: $DASHBOARD_SERVICE"
echo ""

# Detectar puerto (3000 por defecto, pero verificamos)
echo "🔍 Detectando puerto..."
CONTAINER=$(docker ps --filter "name=${DASHBOARD_SERVICE}" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    PORT_3000=$(docker exec $CONTAINER sh -c "netstat -tuln 2>/dev/null | grep ':3000 ' || ss -tuln 2>/dev/null | grep ':3000 '" 2>/dev/null)
    PORT_80=$(docker exec $CONTAINER sh -c "netstat -tuln 2>/dev/null | grep ':80 ' || ss -tuln 2>/dev/null | grep ':80 '" 2>/dev/null)
    
    if [ ! -z "$PORT_3000" ]; then
        DETECTED_PORT=3000
    elif [ ! -z "$PORT_80" ]; then
        DETECTED_PORT=80
    else
        DETECTED_PORT=3000
    fi
else
    DETECTED_PORT=3000
fi

echo "✅ Puerto detectado: $DETECTED_PORT"
echo ""

# Agregar labels de Traefik
echo "🔧 Agregando labels de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=$DETECTED_PORT" \
  --label-add "traefik.docker.network=easypanel" \
  $DASHBOARD_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Labels agregadas"
else
    echo "⚠️ Puede que algunas labels ya existan"
fi

echo ""

# Reiniciar Traefik
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i traefik | head -1)
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    echo "🔄 Reiniciando Traefik..."
    docker service update --force $TRAEFIK_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true
    echo "✅ Traefik reiniciado"
else
    echo "⚠️ No se encontró servicio Traefik"
fi

echo ""
echo "⏳ Esperando 30 segundos para que Traefik se reconfigure..."
sleep 30

echo ""
echo "🧪 Probando acceso HTTPS..."
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com/ 2>&1)

echo ""
echo "=========================================="
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅✅✅ DASHBOARD FUNCIONA CORRECTAMENTE! ✅✅✅"
    echo "   HTTP Status: $HTTPS_CODE"
    echo ""
    echo "🎉 El dashboard debería estar accesible ahora en:"
    echo "   https://dashboard.checkin24hs.com/"
elif [ "$HTTPS_CODE" = "404" ]; then
    echo "❌ AÚN HAY 404"
    echo ""
    echo "🔍 Verificando configuración..."
    echo ""
    echo "Labels actuales:"
    docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{if contains $k "traefik"}}{{$k}}={{$v}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | head -10
    echo ""
    echo "Verifica:"
    echo "  1. DNS: dig +short dashboard.checkin24hs.com"
    echo "  2. Logs Traefik: docker service logs $TRAEFIK_SERVICE --tail 50 | grep dashboard"
    echo "  3. Estado servicio: docker service ps $DASHBOARD_SERVICE"
else
    echo "⚠️ Código HTTP: $HTTPS_CODE"
    echo "   (Puede ser un problema de DNS, SSL, o servicio no disponible)"
fi
echo "=========================================="
