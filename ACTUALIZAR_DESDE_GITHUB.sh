#!/bin/bash
# Script para descargar dashboard.html desde GitHub y copiarlo al contenedor

echo "=========================================="
echo "🔄 Actualizando dashboard.html desde GitHub"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Crear directorio temporal
TEMP_DIR="/tmp/dashboard_update_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "1️⃣ Descargando dashboard.html desde GitHub..."
curl -L -o dashboard.html "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" 2>/dev/null

if [ ! -f "dashboard.html" ]; then
    echo "❌ Error al descargar dashboard.html"
    rm -rf "$TEMP_DIR"
    exit 1
fi

FILE_SIZE=$(stat -c%s dashboard.html 2>/dev/null || stat -f%z dashboard.html 2>/dev/null)
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
echo "✅ Archivo descargado: $FILE_SIZE bytes ($FILE_SIZE_MB MB)"
echo ""

# Verificar BUILD_TIMESTAMP
echo "2️⃣ Verificando BUILD_TIMESTAMP en el archivo descargado..."
BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")

if [ ! -z "$BUILD_TS" ]; then
    BUILD_DATE=$(echo "$BUILD_TS" | cut -d'T' -f1)
    BUILD_TIME=$(echo "$BUILD_TS" | cut -d'T' -f2 | cut -d'Z' -f1)
    echo "✅ BUILD_TIMESTAMP encontrado: $BUILD_DATE $BUILD_TIME"
else
    echo "❌ No se encontró BUILD_TIMESTAMP en el archivo descargado"
    echo "   Esto no debería pasar. Verifica la conexión a GitHub."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verificar DASHBOARD_VERSION
VERSION=$(grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
if [ ! -z "$VERSION" ]; then
    echo "✅ DASHBOARD_VERSION: $VERSION"
else
    echo "⚠️ No se encontró DASHBOARD_VERSION"
fi

# Verificar UTF-8
if grep -q "VERSIÓN:" dashboard.html 2>/dev/null; then
    echo "✅ UTF-8 correcto (tiene 'VERSIÓN' con tilde)"
elif grep -q "VERSI?N:" dashboard.html 2>/dev/null; then
    echo "❌ UTF-8 incorrecto (tiene 'VERSI?N')"
else
    echo "⚠️ No se pudo verificar UTF-8"
fi

echo ""

# Hacer backup
echo "3️⃣ Haciendo backup del archivo actual..."
docker exec "$CONTAINER_ID" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"

echo ""

# Copiar al contenedor
echo "4️⃣ Copiando dashboard.html al contenedor..."
docker cp dashboard.html "$CONTAINER_ID:/app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error al copiar el archivo"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""

# Verificar permisos
echo "5️⃣ Verificando permisos..."
docker exec "$CONTAINER_ID" chmod 644 /app/dashboard.html 2>/dev/null
echo "✅ Permisos verificados"

echo ""

# Verificar en el contenedor
echo "6️⃣ Verificando archivo en el contenedor..."
NEW_BUILD_TS=$(docker exec "$CONTAINER_ID" grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
NEW_VERSION=$(docker exec "$CONTAINER_ID" grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")

if [ ! -z "$NEW_BUILD_TS" ]; then
    echo "✅ BUILD_TIMESTAMP en contenedor: $NEW_BUILD_TS"
else
    echo "❌ No se encontró BUILD_TIMESTAMP en el contenedor"
fi

if [ ! -z "$NEW_VERSION" ]; then
    echo "✅ DASHBOARD_VERSION en contenedor: $NEW_VERSION"
else
    echo "❌ No se encontró DASHBOARD_VERSION en el contenedor"
fi

echo ""

# Verificar servidor
echo "7️⃣ Verificando que el servidor responde..."
sleep 2
SERVER_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    console.log('Status:', res.statusCode);
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Servidor responde correctamente"
else
    echo "⚠️ El servidor puede necesitar reinicio"
fi

echo ""

# Limpiar
echo "8️⃣ Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ ! -z "$NEW_BUILD_TS" ] && [ ! -z "$NEW_VERSION" ]; then
    echo "✅ Dashboard actualizado correctamente desde GitHub"
    echo ""
    echo "📊 Información:"
    echo "   - Versión: $NEW_VERSION"
    echo "   - Build: $NEW_BUILD_TS"
    echo ""
    echo "🌐 Prueba el dashboard:"
    echo "   https://dashboard.checkin24hs.com"
    echo ""
    echo "   ⚠️ IMPORTANTE:"
    echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
    echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
    echo "   3. Verifica que los caracteres especiales se muestren correctamente"
    echo ""
    echo "   ⚠️ NOTA: Esta es una solución TEMPORAL"
    echo "   El archivo se sobrescribirá en el próximo deploy"
    echo "   Para hacerlo permanente, haz rebuild sin caché en EasyPanel"
else
    echo "⚠️ La actualización puede no estar completa"
    echo "   Verifica los errores arriba"
fi

echo ""
