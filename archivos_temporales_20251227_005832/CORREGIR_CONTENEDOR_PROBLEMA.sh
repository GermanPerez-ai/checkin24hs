#!/bin/bash
# Script para corregir el contenedor problemático

PROBLEMA_CONTAINER="checkin24hs_dashboard.1.qs27okwhd2mu8ibay1q8qqc3e"

echo "🔧 Corrigiendo contenedor problemático: $PROBLEMA_CONTAINER"
echo ""

# Verificar que el archivo en el servidor está correcto
echo "📋 Verificando archivo en servidor..."
LINE_5150_SERVER=$(sed -n '5150p' /root/checkin24hs/deploy/dashboard.html)
if echo "$LINE_5150_SERVER" | grep -q "var date = null"; then
    echo "✅ Archivo en servidor está correcto"
else
    echo "⚠️ Archivo en servidor: $LINE_5150_SERVER"
fi

echo ""
echo "📤 Copiando archivo correcto al contenedor..."
docker cp /root/checkin24hs/deploy/dashboard.html $PROBLEMA_CONTAINER:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
    
    echo ""
    echo "🔍 Verificando que se copió correctamente..."
    LINE_5150=$(docker exec $PROBLEMA_CONTAINER sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if echo "$LINE_5150" | grep -q "var date = null"; then
        echo "✅ Línea 5150 correcta: $LINE_5150"
    else
        echo "⚠️ Línea 5150: $LINE_5150"
    fi
    
    SHOW_SECTION_LINE=$(docker exec $PROBLEMA_CONTAINER grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
    if [ ! -z "$SHOW_SECTION_LINE" ] && [ "$SHOW_SECTION_LINE" -lt 2000 ]; then
        echo "✅ Funciones globales en línea $SHOW_SECTION_LINE (correcto)"
    else
        echo "⚠️ Funciones globales en línea $SHOW_SECTION_LINE"
    fi
    
    echo ""
    echo "🔄 Reiniciando contenedor..."
    docker restart $PROBLEMA_CONTAINER
    
    if [ $? -eq 0 ]; then
        echo "✅ Contenedor reiniciado"
        echo ""
        echo "✅ Proceso completado!"
        echo ""
        echo "🌐 Verifica en: https://dashboard.checkin24hs.com/"
        echo "💡 Limpia la caché del navegador (Ctrl + Shift + R)"
    else
        echo "⚠️ Error reiniciando contenedor"
    fi
else
    echo "❌ Error copiando archivo"
fi




