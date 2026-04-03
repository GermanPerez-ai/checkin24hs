#!/bin/bash
# Verificar en qué IP está escuchando el puerto 3000

echo "=== 1. Ver qué está escuchando en el puerto 3000 ==="
netstat -tulpn | grep 3000 || ss -tulpn | grep 3000

echo ""
echo "=== 2. Ver configuración del servidor dashboard ==="
grep -n "listen\|app.listen" ~/checkin24hs/server.js | head -5

echo ""
echo "=== 3. Si está escuchando solo en localhost, necesitamos cambiarlo a 0.0.0.0 ==="

