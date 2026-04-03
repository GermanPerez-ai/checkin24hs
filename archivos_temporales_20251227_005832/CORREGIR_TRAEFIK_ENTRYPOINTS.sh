#!/bin/bash
# Corregir entrypoints y hacer que Traefik use el nombre del servicio

echo "=== 1. Actualizar servicio para incluir entrypoint 'web' ==="
docker service update \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  dashboard-proxy-service

echo ""
echo "=== 2. Verificar que Traefik pueda acceder usando el nombre del servicio ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://dashboard-proxy-service:80 2>&1 | head -5

echo ""
echo "=== 3. Si no funciona, verificar redes ==="
echo "Redes del servicio:"
docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{.NetworkID}} {{end}}'
echo ""
echo "Redes de Traefik:"
docker inspect traefik.1.1qfkazdh5m0czg2hslan0ny0g --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}'

echo ""
echo "=== 4. Esperar y probar acceso ==="
sleep 10
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10

