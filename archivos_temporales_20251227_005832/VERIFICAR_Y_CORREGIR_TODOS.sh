#!/bin/bash
# Script para verificar y corregir TODOS los contenedores

cd /root/checkin24hs

echo "🔍 Verificando archivo en servidor..."
LINE_5150_SERVER=$(sed -n '5150p' deploy/dashboard.html)
if echo "$LINE_5150_SERVER" | grep -q "if (!dateValue)"; then
    echo "✅ Archivo en servidor correcto (línea 5150: if (!dateValue))"
else
    echo "⚠️ Archivo en servidor línea 5150: $LINE_5150_SERVER"
fi

SHOW_SECTION_LINE_SERVER=$(grep -n "window.showSection = function" deploy/dashboard.html | head -1 | cut -d: -f1)
echo "Funciones globales en servidor (línea $SHOW_SECTION_LINE_SERVER)"
echo ""

echo "📤 Verificando y corrigiendo TODOS los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "=== Contenedor: $container ==="
    
    # Verificar línea 5150
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    LINE_5153=$(docker exec $container sed -n '5153p' /app/dashboard.html 2>/dev/null)
    
    # Verificar si necesita corrección
    NEEDS_FIX=false
    
    if echo "$LINE_5150" | grep -q "/*"; then
        echo "❌ Línea 5150 tiene comentario (/*) - necesita corrección"
        NEEDS_FIX=true
    elif ! echo "$LINE_5150" | grep -q "if (!dateValue)"; then
        echo "⚠️ Línea 5150 diferente: $LINE_5150"
        NEEDS_FIX=true
    fi
    
    SHOW_SECTION_LINE=$(docker exec $container grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
    if [ -z "$SHOW_SECTION_LINE" ] || [ "$SHOW_SECTION_LINE" -gt 2000 ]; then
        echo "❌ Funciones globales en línea $SHOW_SECTION_LINE (deberían estar < 2000) - necesita corrección"
        NEEDS_FIX=true
    fi
    
    if [ "$NEEDS_FIX" = true ]; then
        echo "📤 Copiando archivo correcto..."
        docker cp deploy/dashboard.html $container:/app/dashboard.html
        
        # Verificar después de copiar
        sleep 1
        LINE_5150_NEW=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        if echo "$LINE_5150_NEW" | grep -q "if (!dateValue)"; then
            echo "✅ Archivo copiado correctamente"
        else
            echo "⚠️ Archivo copiado pero línea 5150: $LINE_5150_NEW"
        fi
        
        echo "🔄 Reiniciando contenedor..."
        docker restart $container
        echo "✅ Contenedor reiniciado"
    else
        echo "✅ Contenedor ya tiene el archivo correcto"
        echo "   Línea 5150: $LINE_5150"
        echo "   Funciones globales en línea: $SHOW_SECTION_LINE"
    fi
    
    echo ""
done

echo "✅ Proceso completado!"
echo ""
echo "🌐 Verifica en: https://dashboard.checkin24hs.com/"
echo "💡 IMPORTANTE: Limpia completamente la caché del navegador"




