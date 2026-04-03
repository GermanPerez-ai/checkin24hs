#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=== Agregar label 'web' entrypoint ==="
docker service update --label-add "traefik.http.routers.dashboard.entrypoints=web" "$SERVICE_NAME"
echo "✅ Label agregada"
echo ""

echo "=== Esperando 10 segundos ==="
sleep 10
echo ""

echo "=== Verificar todas las labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Verificar Traefik ==="
TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "Traefik: $TRAEFIK_SERVICE"
    echo ""
    echo "=== Logs de Traefik (últimas 30 líneas con 'dashboard') ==="
    docker service logs "$TRAEFIK_SERVICE" --tail 100 2>&1 | grep -i "dashboard\|checkin24hs" | tail -15 || echo "(no hay logs relevantes)"
fi
echo ""

echo "=== Esperando 20 segundos adicionales ==="
sleep 20
echo ""

echo "=== Probar HTTP ==="
curl -I http://$DOMAIN 2>&1 | head -3
echo ""

echo "=== Probar HTTPS ==="
curl -I https://$DOMAIN 2>&1 | head -3
echo ""
