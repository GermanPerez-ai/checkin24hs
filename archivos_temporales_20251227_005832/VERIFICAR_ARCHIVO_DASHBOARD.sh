#!/bin/bash
# Verificar qué archivo se está sirviendo

echo "=== 1. Ver contenido del dashboard.html ==="
head -20 ~/checkin24hs/dashboard.html

echo ""
echo "=== 2. Ver tamaño del archivo ==="
ls -lh ~/checkin24hs/dashboard.html

echo ""
echo "=== 3. Ver qué está sirviendo el servidor ==="
curl -s http://localhost:3000 | head -20

echo ""
echo "=== 4. Verificar server.js - qué archivo está configurado para servir ==="
grep -n "dashboard\|sendFile\|static" ~/checkin24hs/server.js | head -10

echo ""
echo "=== 5. Ver si hay otros archivos HTML en el directorio ==="
ls -lh ~/checkin24hs/*.html 2>/dev/null

