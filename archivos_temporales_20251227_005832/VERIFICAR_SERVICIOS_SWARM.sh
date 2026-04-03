#!/bin/bash
# Verificar servicios Docker Swarm que puedan estar interfiriendo

echo "=== 1. Ver servicios Docker Swarm ==="
docker service ls | grep -i dashboard

echo ""
echo "=== 2. Ver detalles del servicio checkin24hs_dashboard si existe ==="
docker service inspect checkin24hs_dashboard --pretty 2>/dev/null || echo "Servicio no encontrado"

echo ""
echo "=== 3. Ver contenedores del servicio ==="
docker ps | grep checkin24hs_dashboard

echo ""
echo "=== 4. Verificar configuración de Traefik (providers) ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g cat /etc/traefik/traefik.yml 2>/dev/null | grep -A 5 "providers" || echo "No se puede acceder a la configuración"

echo ""
echo "=== 5. Si hay un servicio Swarm, necesitamos actualizarlo o eliminarlo ==="

