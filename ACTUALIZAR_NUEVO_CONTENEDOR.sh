#!/bin/bash
# Script para actualizar el nuevo contenedor del dashboard

CONTAINER_ID="7297fcd6d32a"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"

echo "=========================================="
echo "🔄 ACTUALIZANDO NUEVO CONTENEDOR"
echo "=========================================="
echo ""

# Verificar que el contenedor existe
if ! docker ps | grep -q "$CONTAINER_ID"; then
    echo "❌ El contenedor $CONTAINER_ID no está corriendo"
    echo "   Buscando contenedor activo..."
    CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ No se encontró contenedor activo"
        exit 1
    fi
    echo "   Contenedor encontrado: $CONTAINER_ID"
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# Buscar archivo
DASHBOARD_PATH="/app/dashboard.html"
if ! docker exec "$CONTAINER_ID" test -f "$DASHBOARD_PATH" 2>/dev/null; then
    for path in "/app/dashboard.html" "/usr/share/nginx/html/dashboard.html" "/var/www/html/dashboard.html"; do
        if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
            DASHBOARD_PATH="$path"
            break
        fi
    done
fi

echo "📁 Ruta: $DASHBOARD_PATH"
echo ""

# Verificar versión actual
CURRENT_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$DASHBOARD_PATH" 2>/dev/null | head -1)
echo "Build actual: #${CURRENT_BUILD:-unknown}"

# Verificar versión en GitHub
GITHUB_BUILD=$(curl -s -L "$GITHUB_REPO" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
echo "Build en GitHub: #$GITHUB_BUILD"
echo ""

if [ "$CURRENT_BUILD" = "$GITHUB_BUILD" ]; then
    echo "✅ Ya está actualizado"
    exit 0
fi

# Backup
echo "💾 Creando backup..."
docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "${DASHBOARD_PATH}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
echo ""

# Descargar y copiar
echo "📥 Descargando desde GitHub..."
TEMP_FILE="/tmp/dashboard_new_$$.html"
curl -s -L "$GITHUB_REPO" -o "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    echo "❌ Error al descargar"
    rm -f "$TEMP_FILE"
    exit 1
fi

FILE_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || stat -f%z "$TEMP_FILE" 2>/dev/null)
echo "✅ Descargado: $FILE_SIZE bytes"
echo ""

# Copiar al contenedor
echo "📤 Copiando al contenedor..."
docker cp "$TEMP_FILE" "${CONTAINER_ID}:${DASHBOARD_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
    
    # Verificar
    sleep 2
    NEW_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$DASHBOARD_PATH" 2>/dev/null | head -1)
    if [ -n "$NEW_BUILD" ]; then
        echo "✅ Verificación: Build #$NEW_BUILD"
    fi
    
    # Reiniciar contenedor
    echo ""
    echo "🔄 Reiniciando contenedor..."
    docker restart "$CONTAINER_ID"
    sleep 10
    
    echo ""
    echo "✅ ACTUALIZACIÓN COMPLETADA"
    echo ""
    echo "📋 IMPORTANTE: Esta actualización es TEMPORAL"
    echo "   Se perderá si el servicio se reinicia automáticamente."
    echo ""
    echo "   Para hacerla PERMANENTE, haz rebuild en EasyPanel:"
    echo "   1. Abre EasyPanel"
    echo "   2. Ve al servicio 'dashboard'"
    echo "   3. Haz clic en 'Implementar' o 'Rebuild'"
    echo "   4. Espera 5-10 minutos"
else
    echo "❌ Error al copiar"
fi

rm -f "$TEMP_FILE"
