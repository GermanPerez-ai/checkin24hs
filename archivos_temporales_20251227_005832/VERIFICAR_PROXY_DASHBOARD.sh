#!/bin/bash
# Verificar que el proxy del dashboard funcione

echo "=== 1. Ver estado del contenedor ==="
docker ps | grep dashboard-nginx-proxy

echo ""
echo "=== 2. Ver logs del contenedor ==="
docker logs dashboard-nginx-proxy --tail 10

echo ""
echo "=== 3. Verificar que Traefik lo detectó ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard || echo "Verificar en Traefik dashboard"

echo ""
echo "=== 4. Probar acceso interno ==="
docker exec dashboard-nginx-proxy wget -qO- http://localhost/ | head -5 || echo "Error al acceder"

echo ""
echo "=== 5. Verificar IP del host ==="
docker exec dashboard-nginx-proxy ping -c 1 172.17.0.1 2>/dev/null || echo "Verificando conectividad..."

echo ""
echo "=== 6. Probar desde el host ==="
curl -s http://localhost:3000 | head -3

echo ""
echo "✅ Si todo está bien, el dashboard debería estar accesible en:"
echo "   http://dashboard.checkin24hs.com"

