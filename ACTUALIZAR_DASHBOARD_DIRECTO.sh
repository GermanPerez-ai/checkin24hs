#!/bin/bash
# Script para actualizar el dashboard directamente desde GitHub

CONTAINER_ID="785847bc789e"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"

echo "=========================================="
echo "🔄 ACTUALIZANDO DASHBOARD DESDE GITHUB"
echo "=========================================="
echo ""

# 1. Buscar el archivo dashboard.html en el contenedor
echo "1️⃣ Buscando archivo dashboard.html en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
    "/app/deploy/dashboard.html"
    "/app/index.html"
)

DASHBOARD_PATH=""
for path in "${DASHBOARD_PATHS[@]}"; do
    if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
        DASHBOARD_PATH="$path"
        echo "✅ Archivo encontrado en: $path"
        break
    fi
done

if [ -z "$DASHBOARD_PATH" ]; then
    echo "❌ No se encontró dashboard.html"
    echo "   Listando archivos en /app:"
    docker exec "$CONTAINER_ID" ls -la /app 2>/dev/null | head -20
    exit 1
fi

echo ""

# 2. Verificar versión actual
echo "2️⃣ Verificando versión actual..."
CURRENT_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$DASHBOARD_PATH" 2>/dev/null | head -1)
if [ -z "$CURRENT_BUILD" ]; then
    CURRENT_BUILD="unknown"
fi
echo "   Build actual: #$CURRENT_BUILD"

# Verificar versión en GitHub
GITHUB_BUILD=$(curl -s -L "$GITHUB_REPO" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
echo "   Build en GitHub: #$GITHUB_BUILD"
echo ""

# 3. Crear backup
echo "3️⃣ Creando backup..."
BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "${DASHBOARD_PATH}.${BACKUP_NAME}" 2>/dev/null && echo "✅ Backup creado: ${BACKUP_NAME}" || echo "⚠️ No se pudo crear backup"
echo ""

# 4. Descargar desde GitHub
echo "4️⃣ Descargando desde GitHub..."
TEMP_FILE="/tmp/dashboard_new_$$.html"
curl -s -L "$GITHUB_REPO" -o "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    echo "❌ Error al descargar desde GitHub"
    rm -f "$TEMP_FILE"
    exit 1
fi

FILE_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || stat -f%z "$TEMP_FILE" 2>/dev/null)
echo "✅ Archivo descargado: $FILE_SIZE bytes"
echo ""

# 5. Copiar al contenedor
echo "5️⃣ Copiando al contenedor..."
docker cp "$TEMP_FILE" "${CONTAINER_ID}:${DASHBOARD_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
    
    # Verificar
    sleep 2
    NEW_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$DASHBOARD_PATH" 2>/dev/null | head -1)
    if [ -n "$NEW_BUILD" ]; then
        echo "✅ Verificación: Build #$NEW_BUILD en el contenedor"
    else
        echo "⚠️ No se pudo verificar el build"
    fi
    
    # Reiniciar contenedor
    echo ""
    echo "6️⃣ Reiniciando contenedor..."
    docker restart "$CONTAINER_ID"
    sleep 5
    
    if docker ps | grep -q "$CONTAINER_ID"; then
        echo "✅ Contenedor reiniciado y corriendo"
    else
        echo "⚠️ Verificando estado del contenedor..."
        sleep 5
        docker ps | grep "$CONTAINER_ID" || echo "   El contenedor puede haberse reiniciado (normal en Docker Swarm)"
    fi
else
    echo "❌ Error al copiar archivo"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Limpiar
rm -f "$TEMP_FILE"

echo ""
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Espera 10-15 segundos para que el contenedor termine de iniciar"
echo "   2. Limpia la caché del navegador (Ctrl+Shift+R)"
echo "   3. Recarga el dashboard: https://dashboard.checkin24hs.com"
echo ""
echo "⚠️ NOTA: Esta actualización es TEMPORAL"
echo "   Se perderá al hacer rebuild del servicio."
echo "   Para hacerla permanente, haz rebuild en EasyPanel."
echo ""
