#!/bin/bash
# Script para aplicar el dashboard.html corregido a los contenedores Docker
# Ejecutar desde /root/checkin24hs en el servidor

cd /root/checkin24hs || exit 1

echo "🚀 Aplicando dashboard.html corregido a los contenedores Docker..."
echo ""

FILE_SOURCE="deploy/dashboard.html"

if [ ! -f "$FILE_SOURCE" ]; then
    echo "❌ Error: El archivo fuente $FILE_SOURCE no existe en el directorio actual."
    exit 1
fi

echo "✅ Archivo fuente encontrado: $FILE_SOURCE"
echo "   Tamaño: $(ls -lh "$FILE_SOURCE" | awk '{print $5}')"
HTML_COUNT=$(grep -c '<html' "$FILE_SOURCE" 2>/dev/null || echo "0")
echo "   Tags <html>: $HTML_COUNT"
if [ "$HTML_COUNT" -ne 1 ]; then
    echo "   ⚠️ ADVERTENCIA: El archivo tiene $HTML_COUNT tags <html> (debería ser 1)"
fi
echo ""

# Buscar contenedores de dashboard
echo "🔍 Buscando contenedores de dashboard..."
CONTAINERS=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo "⚠️ No se encontraron contenedores con el nombre 'checkin24hs_dashboard'."
    echo "   Buscando contenedores relacionados con dashboard..."
    CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i dashboard || echo "")
    if [ -z "$CONTAINERS" ]; then
        echo "❌ No se encontraron contenedores relacionados con dashboard."
        echo ""
        echo "Contenedores disponibles:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        exit 1
    fi
fi

echo "✅ Contenedores encontrados:"
echo "$CONTAINERS" | while read -r CONTAINER; do
    echo "   - $CONTAINER"
done
echo ""

SUCCESS_COUNT=0
RESTART_COUNT=0

for CONTAINER in $CONTAINERS; do
    echo "📦 Procesando contenedor: $CONTAINER"
    
    # Intentar copiar a diferentes rutas comunes
    COPIED=false
    
    PATHS=(
        "/app/dashboard.html"
        "/usr/share/nginx/html/dashboard.html"
        "/var/www/html/dashboard.html"
    )
    
    for TARGET_PATH in "${PATHS[@]}"; do
        if docker cp "$FILE_SOURCE" "$CONTAINER:$TARGET_PATH" 2>/dev/null; then
            echo "   ✅ Copiado a: $TARGET_PATH"
            COPIED=true
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            
            # Verificar que se copió correctamente
            CONTAINER_HTML_COUNT=$(docker exec "$CONTAINER" grep -c '<html' "$TARGET_PATH" 2>/dev/null || echo "0")
            if [ "$CONTAINER_HTML_COUNT" -eq 1 ]; then
                echo "   ✅ Verificación: El archivo dentro del contenedor tiene 1 tag <html> (correcto)"
            else
                echo "   ⚠️ ADVERTENCIA: El archivo dentro del contenedor tiene $CONTAINER_HTML_COUNT tags <html>"
            fi
            break
        fi
    done
    
    if [ "$COPIED" = false ]; then
        echo "   ❌ Error: No se pudo copiar $FILE_SOURCE a ninguna de las rutas conocidas en $CONTAINER."
        echo "      Intentando encontrar la ruta del archivo en el contenedor..."
        docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | head -3 || echo "      No se encontró dashboard.html en el contenedor"
        continue
    fi
    
    # Reiniciar el contenedor
    echo "   🔄 Reiniciando contenedor..."
    if docker restart "$CONTAINER" >/dev/null 2>&1; then
        echo "   ✅ Contenedor reiniciado: $CONTAINER"
        RESTART_COUNT=$((RESTART_COUNT + 1))
    else
        echo "   ❌ Error: No se pudo reiniciar el contenedor $CONTAINER."
    fi
    echo ""
done

echo "=== Resumen de la aplicación ==="
echo "✅ Archivos copiados exitosamente a $SUCCESS_COUNT contenedor(es)."
echo "🔄 $RESTART_COUNT contenedor(es) reiniciado(s)."
echo ""
echo "📋 Próximos pasos:"
echo "1. Espera 15-20 segundos para que los contenedores inicien completamente."
echo "2. Recarga el dashboard en tu navegador con Ctrl+F5 (o Cmd+Shift+R en Mac) para limpiar la caché."
echo "3. Verifica que los elementos de WhatsApp y Conocimiento por Hotel aparezcan."
echo ""
echo "💡 Si aún no ves los cambios, verifica:"
echo "   - Que la caché del navegador esté completamente limpiada"
echo "   - Que estés accediendo al dashboard correcto (puede haber múltiples instancias)"
echo "   - Los logs del contenedor: docker logs $CONTAINERS | tail -20"

