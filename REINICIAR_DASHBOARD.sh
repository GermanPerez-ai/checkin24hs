#!/bin/bash
# Reiniciar dashboard con nueva configuración

echo "=== Reiniciar dashboard ==="
pm2 restart dashboard

echo ""
echo "=== Esperar 3 segundos ==="
sleep 3

echo ""
echo "=== Verificar que está escuchando en 0.0.0.0 ==="
netstat -tulpn | grep 3000 || ss -tulpn | grep 3000

echo ""
echo "=== Probar acceso desde el contenedor ==="
docker exec dashboard-nginx-proxy wget -qO- --timeout=3 http://10.11.0.1:3000 2>&1 | head -5

echo ""
echo "=== Probar acceso local ==="
curl -s http://localhost:3000 | head -3

echo ""
echo "✅ Si todo funciona, el dashboard debería estar accesible en:"
echo "   http://dashboard.checkin24hs.com"

