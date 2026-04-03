#!/bin/bash
# Script para verificar y copiar el archivo correcto

echo "🔍 Verificando archivo en el servidor..."
echo ""

# Verificar que el archivo tiene las correcciones
if grep -q "const normalizeDate = function" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo en servidor tiene las correcciones"
else
    echo "❌ Archivo en servidor NO tiene las correcciones"
    echo "   Por favor, sube el archivo corregido desde Windows:"
    echo "   scp deploy\\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

echo ""
echo "📋 Verificando línea 5150 en servidor:"
sed -n '5150p' /root/checkin24hs/deploy/dashboard.html

echo ""
echo "📋 Buscando 'var date = null' en servidor:"
grep -n "var date = null" /root/checkin24hs/deploy/dashboard.html | head -3

echo ""
echo "📤 Copiando a todos los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "📦 Procesando $container..."
    
    # Copiar archivo
    docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    # Verificar que se copió correctamente
    if docker exec $container grep -q "const normalizeDate = function" /app/dashboard.html 2>/dev/null; then
        echo "   ✅ Archivo copiado correctamente (tiene correcciones)"
    else
        echo "   ⚠️ Archivo copiado pero NO tiene correcciones"
    fi
    
    # Reiniciar contenedor
    docker restart $container 2>/dev/null && echo "   ✅ Contenedor reiniciado" || echo "   ⚠️ Error reiniciando"
    echo ""
done

echo "✅ Proceso completado!"




