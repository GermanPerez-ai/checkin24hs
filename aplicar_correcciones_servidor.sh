#!/bin/bash
# Script para aplicar correcciones del Dashboard en el servidor

echo "=== Aplicar Correcciones del Dashboard ==="
echo ""

# 1. Verificar que el archivo existe
if [ ! -f "/root/checkin24hs/deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra /root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

echo "📋 Archivo encontrado: /root/checkin24hs/deploy/dashboard.html"
echo ""

# 2. Obtener contenedor del Dashboard
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: No se encontró el contenedor del Dashboard"
    echo "   Verificando servicios..."
    docker service ls | grep dashboard
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 3. Copiar archivo al contenedor
echo "📤 Copiando dashboard.html al contenedor..."
docker cp /root/checkin24hs/deploy/dashboard.html $CONTAINER_ID:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
    echo ""
    
    # 4. Verificar correcciones
    echo "🔍 Verificando correcciones aplicadas..."
    echo ""
    
    echo "1. Verificando loadWhatsAppCards comentado:"
    docker exec $CONTAINER_ID grep -n "// window.loadWhatsAppCards" /app/dashboard.html | head -1
    
    echo ""
    echo "2. Verificando HTTPS en iframes:"
    docker exec $CONTAINER_ID grep -n "whatsapp1.checkin24hs.com" /app/dashboard.html | head -1
    
    echo ""
    echo "3. Verificando que no hay HTTP en iframes:"
    HTTP_COUNT=$(docker exec $CONTAINER_ID grep -c "http://72.61.58.240:300[1-4]" /app/dashboard.html 2>/dev/null || echo "0")
    if [ "$HTTP_COUNT" -eq "0" ]; then
        echo "   ✅ No se encontraron referencias HTTP en iframes"
    else
        echo "   ⚠️  Se encontraron $HTTP_COUNT referencias HTTP (pueden ser en código JavaScript)"
    fi
    
    echo ""
    echo "✅ Correcciones aplicadas correctamente"
    echo ""
    echo "💡 Recarga el Dashboard con Ctrl+F5 para ver los cambios"
else
    echo "❌ Error al copiar el archivo"
    exit 1
fi


















