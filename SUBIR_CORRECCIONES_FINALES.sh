#!/bin/bash

echo "=========================================="
echo "📤 Subir correcciones finales al servidor"
echo "=========================================="
echo ""

# Desde tu computadora, ejecuta estos comandos:

echo "1️⃣ Subir serve-dashboard.js corregido:"
echo "   scp serve-dashboard.js root@72.61.58.240:/root/checkin24hs/"
echo ""

echo "2️⃣ Subir dashboard.html corregido:"
echo "   scp dashboard.html root@72.61.58.240:/root/checkin24hs/"
echo ""

echo "3️⃣ En el servidor, ejecutar:"
echo "   cd /root/checkin24hs"
echo "   cp dashboard.html deploy/dashboard.html"
echo "   pm2 restart dashboard"
echo "   sleep 3"
echo "   pm2 logs dashboard --lines 5 --nostream"
echo ""

echo "4️⃣ Verificar que index.html no se esté sirviendo:"
echo "   curl http://localhost:3000/ | head -20"
echo ""

echo "✅ Después de subir los archivos, el dashboard debería funcionar sin login"

