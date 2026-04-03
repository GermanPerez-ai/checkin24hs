#!/bin/bash
# Script para aplicar dashboard.html corregido en todos los contenedores

cd /root/checkin24hs

echo "🔍 Verificando archivo en servidor..."
echo ""

# Verificar funciones globales
SHOW_SECTION_LINE=$(grep -n "window.showSection = function" deploy/dashboard.html | head -1 | cut -d: -f1)
if [ ! -z "$SHOW_SECTION_LINE" ] && [ "$SHOW_SECTION_LINE" -lt 2000 ]; then
    echo "✅ Funciones globales en línea $SHOW_SECTION_LINE (correcto)"
else
    echo "⚠️ Funciones globales en línea $SHOW_SECTION_LINE (puede estar mal)"
fi

# Verificar línea 5150
LINE_5150=$(sed -n '5150p' deploy/dashboard.html)
if echo "$LINE_5150" | grep -q "var date = null"; then
    echo "✅ Línea 5150 correcta: var date = null"
else
    echo "⚠️ Línea 5150: $LINE_5150"
fi

# Verificar tamaño
echo ""
echo "📋 Tamaño del archivo:"
ls -lh deploy/dashboard.html

echo ""
echo "📤 Copiando a todos los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "📦 Procesando $container..."
    
    # Copiar archivo
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Verificar que se copió correctamente
        if docker exec $container grep -q "const normalizeDate = function" /app/dashboard.html 2>/dev/null; then
            SHOW_SECTION_LINE=$(docker exec $container grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
            if [ ! -z "$SHOW_SECTION_LINE" ] && [ "$SHOW_SECTION_LINE" -lt 2000 ]; then
                echo "   ✅ Funciones globales correctas (línea $SHOW_SECTION_LINE)"
            else
                echo "   ⚠️ Funciones globales en línea $SHOW_SECTION_LINE"
            fi
            
            LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
            if echo "$LINE_5150" | grep -q "var date = null"; then
                echo "   ✅ Línea 5150 correcta"
            else
                echo "   ⚠️ Línea 5150: $LINE_5150"
            fi
        else
            echo "   ❌ Archivo NO tiene correcciones"
        fi
        
        # Reiniciar contenedor
        docker restart $container 2>/dev/null && echo "   ✅ Contenedor reiniciado" || echo "   ⚠️ Error reiniciando"
    else
        echo "   ❌ Error copiando archivo"
    fi
    
    echo ""
done

echo "✅ Proceso completado!"
echo ""
echo "🌐 Verifica los cambios en: https://dashboard.checkin24hs.com/"
echo "💡 IMPORTANTE: Limpia la caché del navegador completamente"




