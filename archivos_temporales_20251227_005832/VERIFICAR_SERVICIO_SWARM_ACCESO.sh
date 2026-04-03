#!/bin/bash
# Verificar si el servicio Swarm puede acceder al contenedor proxy

echo "=== 1. Ver contenedores del servicio Swarm ==="
docker service ps dashboard-proxy-service

echo ""
echo "=== 2. Obtener ID del contenedor del servicio ==="
SERVICE_CONTAINER=$(docker service ps dashboard-proxy-service --format '{{.Name}}' | head -1)
echo "Contenedor: $SERVICE_CONTAINER"

echo ""
echo "=== 3. Probar acceso desde el contenedor del servicio al proxy ==="
docker exec $(docker ps --filter "name=$SERVICE_CONTAINER" --format "{{.ID}}") wget -qO- --timeout=5 http://dashboard-nginx-proxy:80 2>&1 | head -5

echo ""
echo "=== 4. Verificar redes del servicio ==="
docker service inspect dashboard-proxy-service --format '{{range .Endpoint.VirtualIPs}}{{.NetworkID}} {{end}}'

echo ""
echo "=== 5. Verificar si Traefik puede resolver el nombre ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g nslookup dashboard-nginx-proxy 2>/dev/null || echo "No se puede resolver"

echo ""
echo "=== 6. Ver logs de Traefik para ver el error específico ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 20 | grep -i "dashboard\|502\|error" | tail -5

