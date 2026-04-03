#!/bin/bash
# Script para aplicar dashboard.html corregido en el servidor

echo "🔍 Buscando contenedores Docker..."

# Buscar contenedor Dashboard
DASHBOARD_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i dashboard | head -1)

if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "✅ Contenedor Dashboard encontrado: $DASHBOARD_CONTAINER"
    echo ""
    
    # Verificar que el archivo existe
    if [ ! -f "/root/checkin24hs/deploy/dashboard.html" ]; then
        echo "❌ Error: No se encontró /root/checkin24hs/deploy/dashboard.html"
        echo "   Por favor, sube el archivo primero desde tu máquina Windows"
        exit 1
    fi
    
    echo "📤 Copiando dashboard.html al contenedor..."
    
    # Intentar copiar a diferentes rutas posibles
    docker cp /root/checkin24hs/deploy/dashboard.html $DASHBOARD_CONTAINER:/usr/share/nginx/html/dashboard.html 2>/dev/null || \
    docker cp /root/checkin24hs/deploy/dashboard.html $DASHBOARD_CONTAINER:/app/dashboard.html 2>/dev/null || \
    docker cp /root/checkin24hs/deploy/dashboard.html $DASHBOARD_CONTAINER:/var/www/html/dashboard.html 2>/dev/null || {
        echo "❌ Error: No se pudo copiar el archivo al contenedor"
        echo "   Rutas intentadas:"
        echo "   - /usr/share/nginx/html/dashboard.html"
        echo "   - /app/dashboard.html"
        echo "   - /var/www/html/dashboard.html"
        exit 1
    }
    
    echo "✅ Archivo copiado correctamente"
    echo ""
    echo "🔄 Reiniciando contenedor..."
    docker restart $DASHBOARD_CONTAINER
    
    echo ""
    echo "✅ Contenedor reiniciado"
    echo ""
    echo "🌐 Verifica los cambios en: https://dashboard.checkin24hs.com/"
    echo "💡 Limpia la caché del navegador (Ctrl + Shift + R)"
    
else
    echo "⚠️ No se encontró contenedor Dashboard"
    echo ""
    echo "📋 Contenedores disponibles:"
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
    echo ""
    echo "💡 Si el dashboard está en otro contenedor, ejecuta manualmente:"
    echo "   docker cp /root/checkin24hs/deploy/dashboard.html <nombre_contenedor>:/ruta/del/archivo/dashboard.html"
    echo "   docker restart <nombre_contenedor>"
fi




