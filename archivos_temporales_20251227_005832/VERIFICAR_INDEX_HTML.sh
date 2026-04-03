#!/bin/bash
# Verificar si existe index.html y qué está sirviendo

echo "=== 1. Verificar si existe index.html ==="
ls -lh ~/checkin24hs/index.html 2>/dev/null || echo "No existe index.html"

echo ""
echo "=== 2. Ver qué archivo está sirviendo realmente ==="
curl -s http://localhost:3000 | grep -i "title\|Panel de Administración\|CHECKIN" | head -3

echo ""
echo "=== 3. Verificar que server.js tenga el cambio ==="
grep -A 2 "Ruta principal" ~/checkin24hs/server.js

echo ""
echo "=== 4. Si existe index.html, renombrarlo temporalmente ==="
if [ -f ~/checkin24hs/index.html ]; then
    mv ~/checkin24hs/index.html ~/checkin24hs/index.html.backup
    echo "✅ index.html renombrado"
    pm2 restart dashboard
    sleep 3
    curl -s http://localhost:3000 | grep -i "title\|Panel de Administración" | head -3
fi

