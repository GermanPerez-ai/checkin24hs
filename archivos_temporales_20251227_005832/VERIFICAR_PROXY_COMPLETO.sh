#!/bin/bash
# Verificar que el proxy funcione completamente

echo "=== 1. Verificar que Nginx esté escuchando en el contenedor ==="
docker exec dashboard-nginx-proxy netstat -tuln | grep 80 || docker exec dashboard-nginx-proxy ss -tuln | grep 80

echo ""
echo "=== 2. Probar acceso a través del proxy (desde dentro del contenedor) ==="
docker exec dashboard-nginx-proxy wget -qO- http://localhost/ 2>&1 | head -5

echo ""
echo "=== 3. Verificar que Traefik detectó el servicio ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard || echo "Verificar en Traefik dashboard"

echo ""
echo "=== 4. Probar acceso desde el host usando el dominio ==="
curl -I http://dashboard.checkin24hs.com 2>&1 | head -10

echo ""
echo "=== 5. Ver logs de Traefik ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 10 | grep -i dashboard || echo "No hay logs recientes de dashboard"

echo ""
echo "✅ Si todo está bien, el dashboard debería estar accesible en:"
echo "   http://dashboard.checkin24hs.com"

