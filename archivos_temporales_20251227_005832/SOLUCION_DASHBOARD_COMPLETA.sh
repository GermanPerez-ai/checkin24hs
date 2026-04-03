#!/bin/bash
# Solución completa para el dashboard

cd ~/checkin24hs

echo "=== 1. Verificar npm install ==="
if [ ! -d "node_modules" ]; then
    echo "Instalando dependencias..."
    npm install
else
    echo "✅ node_modules existe"
    # Verificar que express esté instalado
    if [ ! -d "node_modules/express" ]; then
        echo "⚠️  express no encontrado, reinstalando..."
        npm install express cors
    else
        echo "✅ express está instalado"
    fi
fi

echo ""
echo "=== 2. Verificar dashboard.html ==="
if [ ! -s dashboard.html ]; then
    echo "❌ dashboard.html está vacío"
    echo "Necesitas subirlo desde tu máquina local"
    echo ""
    echo "Desde tu máquina Windows, ejecuta:"
    echo "scp dashboard.html root@72.61.58.240:~/checkin24hs/dashboard.html"
    echo ""
    echo "O súbelo a GitHub primero y luego:"
    echo "git pull origin main"
else
    echo "✅ dashboard.html tiene contenido"
fi

echo ""
echo "=== 3. Verificar archivos de Supabase ==="
ls -lh supabase-config.js supabase-client.js 2>/dev/null

echo ""
echo "=== 4. Si npm install terminó, reiniciar ==="
if [ -d "node_modules/express" ]; then
    echo "Reiniciando dashboard..."
    pm2 restart dashboard
    sleep 5
    pm2 logs dashboard --lines 10 --nostream
    pm2 status | grep dashboard
fi

