#!/bin/bash

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

echo "Contenedor: $CONTAINER"
echo ""

# Buscar específicamente window.buildServerURL
echo "=== Buscando window.buildServerURL ==="
docker exec $CONTAINER grep -n "window.buildServerURL" /app/dashboard.html

echo ""
echo "=== Buscando window.getServerURL ==="
docker exec $CONTAINER grep -n "window.getServerURL" /app/dashboard.html

echo ""
echo "=== Verificando línea 10630 (donde debería estar) ==="
docker exec $CONTAINER sed -n '10628,10632p' /app/dashboard.html








