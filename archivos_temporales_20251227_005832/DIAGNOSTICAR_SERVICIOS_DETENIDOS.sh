#!/bin/bash
# Diagnosticar por qué los servicios están detenidos

cd ~/checkin24hs/whatsapp-server

echo "=== Verificando servicios detenidos ==="
pm2 status | grep stopped

echo ""
echo "=== Ver logs de error de whatsapp-1 ==="
pm2 logs whatsapp-1 --err --lines 20 --nostream | tail -10

echo ""
echo "=== Verificar sintaxis del archivo ==="
node -c whatsapp-server.js 2>&1

echo ""
echo "=== Verificar que no haya referencias rotas ==="
grep -n "cleanChromeLocks" whatsapp-server.js

