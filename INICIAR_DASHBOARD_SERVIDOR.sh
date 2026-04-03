#!/bin/bash
# Iniciar servicio del dashboard

cd ~/checkin24hs

echo "=== Verificando archivos ==="
ls -la server.js dashboard.html 2>/dev/null

echo ""
echo "=== Verificando dependencias ==="
if [ -f "package.json" ]; then
    echo "✅ package.json existe"
    if [ ! -d "node_modules" ]; then
        echo "⚠️  node_modules no existe, instalando..."
        npm install
    else
        echo "✅ node_modules existe"
    fi
else
    echo "⚠️  package.json no encontrado"
fi

echo ""
echo "=== Verificando puerto 3000 ==="
if netstat -tulpn | grep ":3000" > /dev/null 2>&1 || ss -tulpn | grep ":3000" > /dev/null 2>&1; then
    echo "⚠️  Puerto 3000 ya está en uso"
    netstat -tulpn | grep ":3000" || ss -tulpn | grep ":3000"
else
    echo "✅ Puerto 3000 disponible"
fi

echo ""
echo "=== Iniciando servicio con PM2 ==="
# Verificar si ya existe un servicio del dashboard
if pm2 list | grep -i "dashboard\|server" > /dev/null; then
    echo "⚠️  Ya existe un servicio, reiniciando..."
    pm2 restart dashboard || pm2 restart server
else
    echo "✅ Creando nuevo servicio..."
    pm2 start server.js --name dashboard --update-env
fi

echo ""
echo "=== Esperando inicio ==="
sleep 3

echo ""
echo "=== Verificando estado ==="
pm2 list | grep -i "dashboard\|server"

echo ""
echo "=== Verificando puerto ==="
netstat -tulpn | grep ":3000" || ss -tulpn | grep ":3000"

echo ""
echo "=== Ver logs ==="
pm2 logs dashboard --lines 10 --nostream || pm2 logs server --lines 10 --nostream

echo ""
echo "✅ Si el servicio está 'online', el dashboard debería funcionar"

