#!/bin/bash
# Diagnosticar el error 502

echo "=== 1. Ver logs de Nginx en el contenedor ==="
docker logs dashboard-nginx-proxy --tail 20

echo ""
echo "=== 2. Verificar que Nginx esté corriendo ==="
docker exec dashboard-nginx-proxy ps aux | grep nginx

echo ""
echo "=== 3. Probar acceso directo desde otro contenedor en la misma red ==="
docker run --rm --network easypanel alpine wget -qO- --timeout=3 http://dashboard-nginx-proxy/ 2>&1 | head -5

echo ""
echo "=== 4. Verificar labels del contenedor ==="
docker inspect dashboard-nginx-proxy | grep -A 10 "Labels"

echo ""
echo "=== 5. Ver logs de Traefik ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 30 | grep -i "dashboard\|502\|error" || echo "No hay errores recientes"

echo ""
echo "=== 6. Verificar conectividad de red ==="
docker exec dashboard-nginx-proxy ping -c 1 72.61.58.240 2>/dev/null && echo "✅ Puede hacer ping al host" || echo "❌ No puede hacer ping"

echo ""
echo "=== 7. Probar acceso directo al puerto 3000 desde el contenedor ==="
docker exec dashboard-nginx-proxy wget -qO- --timeout=3 http://72.61.58.240:3000 2>&1 | head -3

