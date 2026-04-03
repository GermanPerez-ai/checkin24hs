#!/bin/bash
# Verificar cómo Traefik está accediendo al servicio

echo "=== 1. Ver logs recientes de Traefik ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 30 | grep -i "dashboard\|502\|error" | tail -10

echo ""
echo "=== 2. Obtener IP del contenedor del servicio ==="
SERVICE_CONTAINER=$(docker service ps dashboard-proxy-service --format '{{.Name}}' | head -1)
CONTAINER_ID=$(docker ps --filter "name=$SERVICE_CONTAINER" --format "{{.ID}}")
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del servicio: $CONTAINER_IP"

echo ""
echo "=== 3. Probar acceso desde Traefik al servicio ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$CONTAINER_IP:80 2>&1 | head -5

echo ""
echo "=== 4. Probar acceso usando el nombre del servicio ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://dashboard-proxy-service:80 2>&1 | head -5

echo ""
echo "=== 5. Verificar labels del servicio ==="
docker service inspect dashboard-proxy-service --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik

echo ""
echo "=== 6. Verificar routers en Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard || echo "No se encontró router"

