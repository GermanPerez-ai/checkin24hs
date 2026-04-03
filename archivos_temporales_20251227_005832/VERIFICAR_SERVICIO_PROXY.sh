#!/bin/bash
# Verificar el servicio proxy

echo "=== 1. Ver logs del servicio ==="
docker service logs dashboard-proxy-service --tail 20

echo ""
echo "=== 2. Obtener contenedor del servicio ==="
SERVICE_CONTAINER=$(docker service ps dashboard-proxy-service --format '{{.Name}}' | head -1)
CONTAINER_ID=$(docker ps --filter "name=$SERVICE_CONTAINER" --format "{{.ID}}")
echo "Contenedor: $SERVICE_CONTAINER ($CONTAINER_ID)"

echo ""
echo "=== 3. Verificar configuración Nginx en el contenedor ==="
docker exec $CONTAINER_ID cat /etc/nginx/conf.d/default.conf 2>/dev/null || echo "No se puede acceder"

echo ""
echo "=== 4. Probar acceso al puerto 3000 desde el contenedor ==="
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
docker exec $CONTAINER_ID wget -qO- --timeout=5 http://$HOST_IP:3000 2>&1 | head -5

echo ""
echo "=== 5. Verificar que Nginx esté escuchando ==="
docker exec $CONTAINER_ID netstat -tuln | grep 80 || docker exec $CONTAINER_ID ss -tuln | grep 80

echo ""
echo "=== 6. Probar acceso local al contenedor ==="
docker exec $CONTAINER_ID wget -qO- http://localhost/ 2>&1 | head -5

