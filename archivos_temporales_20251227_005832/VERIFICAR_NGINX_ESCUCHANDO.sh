#!/bin/bash
# Verificar si Nginx está escuchando correctamente

SERVICE_CONTAINER=$(docker service ps dashboard-proxy-service --format '{{.Name}}' | head -1)
CONTAINER_ID=$(docker ps --filter "name=$SERVICE_CONTAINER" --format "{{.ID}}")

echo "=== 1. Verificar que Nginx esté escuchando en el puerto 80 ==="
docker exec $CONTAINER_ID netstat -tuln | grep 80 || docker exec $CONTAINER_ID ss -tuln | grep 80

echo ""
echo "=== 2. Ver procesos de Nginx ==="
docker exec $CONTAINER_ID ps aux | grep nginx

echo ""
echo "=== 3. Probar acceso usando la IP del contenedor ==="
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor: $CONTAINER_IP"
docker run --rm --network easypanel alpine wget -qO- --timeout=5 http://$CONTAINER_IP:80 2>&1 | head -5

echo ""
echo "=== 4. Ver logs de error de Nginx ==="
docker exec $CONTAINER_ID cat /var/log/nginx/error.log 2>/dev/null | tail -10 || echo "No hay logs de error"

echo ""
echo "=== 5. Verificar sintaxis de Nginx ==="
docker exec $CONTAINER_ID nginx -t 2>&1

