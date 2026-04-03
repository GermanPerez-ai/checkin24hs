#!/bin/bash
# Restaurar dashboard.html desde deploy/

cd ~/checkin24hs

echo "=== Copiando dashboard.html desde deploy/ ==="
cp deploy/dashboard.html dashboard.html

echo ""
echo "=== Verificando que se copió ==="
ls -lh dashboard.html

echo ""
echo "=== Verificando contenido ==="
head -5 dashboard.html

echo ""
echo "=== Verificando dependencias ==="
if [ ! -d "node_modules/express" ]; then
    echo "Instalando dependencias..."
    npm install
else
    echo "✅ Dependencias instaladas"
fi

echo ""
echo "=== Reiniciando dashboard ==="
pm2 restart dashboard

echo ""
echo "=== Esperando inicio ==="
sleep 5

echo ""
echo "=== Verificando estado ==="
pm2 status | grep dashboard

echo ""
echo "=== Ver logs ==="
pm2 logs dashboard --lines 10 --nostream

echo ""
echo "=== Verificar puerto 3000 ==="
netstat -tulpn | grep ":3000" || ss -tulpn | grep ":3000"

