#!/bin/bash
# Verificación completa del dashboard

echo "=== 1. Verificar DNS ==="
nslookup dashboard.checkin24hs.com || dig dashboard.checkin24hs.com +short

echo ""
echo "=== 2. Ver estado del contenedor proxy ==="
docker ps | grep dashboard-nginx-proxy

echo ""
echo "=== 3. Ver logs del contenedor ==="
docker logs dashboard-nginx-proxy --tail 20

echo ""
echo "=== 4. Verificar configuración dentro del contenedor ==="
docker exec dashboard-nginx-proxy cat /etc/nginx/conf.d/default.conf 2>/dev/null || echo "No se puede acceder"

echo ""
echo "=== 5. Probar acceso directo al puerto 3000 desde el contenedor ==="
ETH0_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Probando con IP: $ETH0_IP"
docker exec dashboard-nginx-proxy wget -qO- --timeout=3 http://$ETH0_IP:3000 2>&1 | head -5

echo ""
echo "=== 6. Verificar que el dashboard esté corriendo ==="
pm2 status | grep dashboard
netstat -tulpn | grep 3000

echo ""
echo "=== 7. Probar acceso desde el host ==="
curl -s http://localhost:3000 | head -3

echo ""
echo "=== 8. Probar acceso desde el contenedor a través del proxy ==="
docker exec dashboard-nginx-proxy wget -qO- http://localhost/ 2>&1 | head -5

