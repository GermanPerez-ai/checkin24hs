#!/bin/bash
# Reiniciar dashboard de forma forzada

echo "=== 1. Detener dashboard ==="
pm2 stop dashboard

echo ""
echo "=== 2. Eliminar del PM2 y volver a agregar ==="
pm2 delete dashboard

echo ""
echo "=== 3. Verificar que server.js tenga el cambio ==="
grep -A 2 "Ruta principal" ~/checkin24hs/server.js

echo ""
echo "=== 4. Iniciar dashboard de nuevo ==="
cd ~/checkin24hs
pm2 start server.js --name dashboard

echo ""
echo "=== 5. Esperar y verificar ==="
sleep 5
pm2 logs dashboard --lines 5 --nostream

echo ""
echo "=== 6. Probar acceso ==="
curl -s http://localhost:3000 | head -10

