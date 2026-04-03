#!/bin/bash
# Verificar si el contenedor proxy funciona desde la red Docker

echo "=== 1. Obtener IP del contenedor proxy ==="
PROXY_IP=$(docker inspect dashboard-nginx-proxy --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del proxy: $PROXY_IP"

echo ""
echo "=== 2. Probar acceso al contenedor proxy desde otro contenedor en la misma red ==="
docker run --rm --network easypanel alpine wget -qO- --timeout=5 http://$PROXY_IP:80 2>&1 | head -5

echo ""
echo "=== 3. Probar acceso usando el nombre del contenedor ==="
docker run --rm --network easypanel alpine wget -qO- --timeout=5 http://dashboard-nginx-proxy:80 2>&1 | head -5

echo ""
echo "=== 4. Verificar que el contenedor proxy esté escuchando ==="
docker exec dashboard-nginx-proxy netstat -tuln | grep 80

echo ""
echo "=== 5. Ver logs del contenedor proxy ==="
docker logs dashboard-nginx-proxy --tail 10

echo ""
echo "=== 6. Probar acceso directo al puerto 3000 desde el contenedor proxy ==="
ETH0_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
docker exec dashboard-nginx-proxy wget -qO- --timeout=3 http://$ETH0_IP:3000 2>&1 | head -3

