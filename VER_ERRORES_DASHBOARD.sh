#!/bin/bash
# Ver errores del dashboard

cd ~/checkin24hs

echo "=== Errores del dashboard ==="
pm2 logs dashboard --err --lines 30 --nostream

echo ""
echo "=== Logs completos recientes ==="
pm2 logs dashboard --lines 20 --nostream

echo ""
echo "=== Verificar archivo dashboard.html ==="
ls -lh dashboard.html
head -5 dashboard.html

echo ""
echo "=== Verificar dependencias ==="
if [ -f "package.json" ]; then
    echo "package.json existe"
    cat package.json | grep -A 5 "dependencies"
else
    echo "⚠️  package.json no encontrado"
fi

