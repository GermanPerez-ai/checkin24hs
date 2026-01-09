#!/bin/bash

echo "🔧 SOLUCIONANDO ERROR 404 DESPUÉS DE REINICIAR TRAEFIK"
echo "======================================================"
echo ""

# 1. Encontrar servicios
echo "1️⃣ Buscando servicios..."
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio Traefik"
    docker service ls
    exit 1
fi

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

TRAEFIK_NAME=$(docker service ls | grep -i traefik | awk '{print $2}' | head -1)
DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

echo "✅ Traefik: $TRAEFIK_NAME ($TRAEFIK_SERVICE)"
echo "✅ Dashboard: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Agregar labels de Traefik al dashboard
echo "2️⃣ Agregando labels de Traefik al dashboard..."
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
    --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard.tls=true" \
    --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
    --label-add "traefik.docker.network=easypanel" \
    $DASHBOARD_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas correctamente"
else
    echo "❌ Error al agregar labels"
    exit 1
fi
echo ""

# 3. Verificar labels
echo "3️⃣ Verificando labels agregadas..."
docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}'
echo ""

# 4. Esperar a que Traefik detecte los cambios
echo "4️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 5. Verificar estado de Traefik
echo "5️⃣ Verificando estado de Traefik..."
docker service ps $TRAEFIK_SERVICE --no-trunc | head -3
echo ""

# 6. Ver logs de Traefik
echo "6️⃣ Últimos logs de Traefik (buscando dashboard)..."
docker service logs $TRAEFIK_SERVICE --tail 30 2>&1 | grep -i "dashboard\|$DASHBOARD_NAME" | tail -10 || echo "No hay logs relacionados con dashboard"
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Labels de Traefik aplicadas al dashboard"
echo "   - Espera 1-2 minutos más para que Traefik detecte completamente"
echo ""
echo "⏳ PRÓXIMOS PASOS:"
echo "   1. Espera 1-2 minutos"
echo "   2. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo "   3. Si aún no funciona, verifica:"
echo "      - Que el DNS apunte correctamente"
echo "      - Los logs de Traefik: docker service logs $TRAEFIK_NAME --tail 50"
echo ""
