#!/bin/bash
# Corregir Traefik para usar el puerto 3000 del dashboard

echo "=== CORRIGIENDO PUERTO DEL DASHBOARD A 3000 ==="
echo ""

# Obtener VIP del servicio
EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}' 2>/dev/null)
VIP=$(docker service inspect checkin24hs_dashboard --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)

echo "VIP del servicio: $VIP"
echo ""

# Actualizar Traefik para usar puerto 3000 con VIP
echo "Actualizando Traefik para usar puerto 3000..."
docker service update \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server=http://${VIP}:3000" \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

echo "✅ Labels actualizados"
echo "⏳ Esperando 15 segundos para que Traefik recargue..."
sleep 15

echo ""
echo "=== VERIFICANDO ACCESO HTTPS ==="
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com 2>&1)

if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ Dashboard funciona correctamente! (HTTP 200)"
    echo ""
    echo "Verificando contenido..."
    curl -s https://dashboard.checkin24hs.com | head -c 200
    echo ""
else
    echo "⚠️ Aún hay problemas (HTTP $HTTPS_CODE)"
    echo ""
    echo "Verificando conectividad desde Traefik..."
    TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
    if [ -n "$TRAEFIK_CONTAINER" ]; then
        echo "Probando conexión desde Traefik a VIP:3000..."
        docker exec $TRAEFIK_CONTAINER wget -O- --timeout=5 http://${VIP}:3000/dashboard.html 2>&1 | head -10
    fi
fi

echo ""
echo "=== LABELS ACTUALES ==="
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

echo ""






