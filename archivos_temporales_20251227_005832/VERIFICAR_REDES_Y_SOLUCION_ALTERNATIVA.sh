#!/bin/bash
# Verificar redes y probar solución alternativa

echo "=== 1. Verificar redes del servicio ==="
docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{.NetworkID}} {{end}}'

echo ""
echo "=== 2. Verificar redes de Traefik ==="
docker inspect traefik.1.1qfkazdh5m0czg2hslan0ny0g --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}'

echo ""
echo "=== 3. Verificar si el contenedor proxy individual funciona ==="
echo "El contenedor 'dashboard-nginx-proxy' que creamos antes funciona correctamente"
echo "Probando acceso desde Traefik a ese contenedor:"
PROXY_IP=$(docker inspect dashboard-nginx-proxy --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor proxy: $PROXY_IP"
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$PROXY_IP:80 2>&1 | head -5

echo ""
echo "=== 4. Si el contenedor proxy funciona, usar ese en lugar del servicio ==="
echo "O eliminar el servicio y dejar solo el contenedor con labels correctos"

echo ""
echo "=== 5. Probar acceso usando el nombre del contenedor proxy ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://dashboard-nginx-proxy:80 2>&1 | head -5

