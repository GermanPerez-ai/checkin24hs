#!/bin/bash
# Script para buscar la ruta del proyecto en el servidor
# Ejecuta: bash buscar_ruta_servidor.sh

echo "🔍 Buscando la ruta del proyecto Checkin24hs..."
echo ""

echo "📋 Método 1: Buscando server.js..."
find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -10
echo ""

echo "📋 Método 2: Buscando dashboard.html..."
find / -name "dashboard.html" -type f 2>/dev/null | head -5
echo ""

echo "📋 Método 3: Buscando carpeta Checkin24hs..."
find / -type d -name "*checkin*" -o -name "*Checkin*" 2>/dev/null | head -10
echo ""

echo "📋 Método 4: Buscando .git..."
find / -name ".git" -type d 2>/dev/null | grep -v ".git/" | head -10
echo ""

echo "📋 Método 5: Procesos Node.js corriendo..."
ps aux | grep -E "node.*server.js|node.*dashboard" | grep -v grep
echo ""

echo "📋 Método 6: Si usas PM2..."
if command -v pm2 &> /dev/null; then
    pm2 list
else
    echo "PM2 no está instalado o no está en el PATH"
fi
echo ""

echo "📋 Método 7: Verificando rutas comunes..."
for dir in /var/www /home /opt /root /usr/local/www; do
    if [ -d "$dir" ]; then
        echo "Buscando en $dir:"
        find "$dir" -maxdepth 2 -name "*checkin*" -o -name "*Checkin*" 2>/dev/null | head -5
    fi
done

echo ""
echo "✅ Busqueda completada. Revisa las rutas encontradas arriba."
