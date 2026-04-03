#!/bin/bash
# Script para agregar parámetro de versión y forzar recarga

cd /root/checkin24hs

echo "🔍 Verificando archivo actual..."
echo ""

# Verificar que tiene las correcciones
SHOW_SECTION_LINE=$(grep -n "window.showSection = function" deploy/dashboard.html | head -1 | cut -d: -f1)
LINE_5150=$(sed -n '5150p' deploy/dashboard.html)

echo "Funciones globales en línea: $SHOW_SECTION_LINE"
echo "Línea 5150: $LINE_5150"
echo ""

# Agregar timestamp al final del archivo como comentario para forzar recarga
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "<!-- Versión: $TIMESTAMP -->" >> deploy/dashboard.html

echo "✅ Timestamp agregado: $TIMESTAMP"
echo ""

# Copiar a todos los contenedores
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "📦 Copiando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    # Verificar
    if docker exec $container grep -q "const normalizeDate = function" /app/dashboard.html 2>/dev/null; then
        LINE_5150_CONTAINER=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        if echo "$LINE_5150_CONTAINER" | grep -q "var date = null"; then
            echo "   ✅ Archivo correcto"
        else
            echo "   ⚠️ Línea 5150: $LINE_5150_CONTAINER"
        fi
    fi
    
    docker restart $container 2>/dev/null && echo "   ✅ Reiniciado" || echo "   ⚠️ Error"
    echo ""
done

echo "✅ Proceso completado!"
echo ""
echo "🌐 Abre: https://dashboard.checkin24hs.com/?v=$TIMESTAMP"
echo "💡 O limpia completamente la caché del navegador"




