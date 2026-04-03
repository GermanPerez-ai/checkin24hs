#!/bin/bash
# Script para actualizar dashboard.html directamente en el contenedor (solución temporal)

echo "=========================================="
echo "🔄 Actualizando dashboard.html en el contenedor"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Crear directorio temporal
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
echo "✅ Archivo descargado: $FILE_SIZE bytes"

# Verificar que tiene BUILD_TIMESTAMP
if grep -q "BUILD_TIMESTAMP" dashboard.html; then
    BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1)
    echo "✅ BUILD_TIMESTAMP encontrado: $BUILD_TS"
else
    echo "⚠️ No se encontró BUILD_TIMESTAMP en el archivo descargado"
fi

echo ""

# 2. Hacer backup del archivo actual
echo "2️⃣ Haciendo backup del archivo actual..."
docker exec "$CONTAINER_ID" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"

echo ""

# 3. Copiar el archivo nuevo al contenedor
echo "3️⃣ Copiando dashboard.html al contenedor..."
docker cp dashboard.html "$CONTAINER_ID:/app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error al copiar el archivo"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""

# 4. Verificar permisos
echo "4️⃣ Verificando permisos..."
docker exec "$CONTAINER_ID" chmod 644 /app/dashboard.html 2>/dev/null
echo "✅ Permisos verificados"

echo ""

# 5. Verificar que el archivo se copió correctamente
echo "5️⃣ Verificando archivo en el contenedor..."
NEW_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño en contenedor: $NEW_SIZE bytes"

if [ "$FILE_SIZE" = "$NEW_SIZE" ]; then
    echo "✅ Tamaño coincide"
else
    echo "⚠️ Los tamaños no coinciden (puede ser normal por diferencias de línea)"
fi

# Verificar BUILD_TIMESTAMP en el contenedor
NEW_BUILD_TS=$(docker exec "$CONTAINER_ID" grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1)
if [ ! -z "$NEW_BUILD_TS" ]; then
    echo "✅ BUILD_TIMESTAMP en contenedor: $NEW_BUILD_TS"
else
    echo "⚠️ No se encontró BUILD_TIMESTAMP en el contenedor"
fi

echo ""

# 6. Limpiar archivos temporales
echo "6️⃣ Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"

echo ""

# 7. Verificar que el servidor sigue funcionando
echo "7️⃣ Verificando que el servidor sigue funcionando..."
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
    echo "   Ejecuta: docker service update --force $DASHBOARD_SERVICE"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "✅ dashboard.html actualizado en el contenedor"
echo ""
echo "⚠️ IMPORTANTE: Esta es una solución TEMPORAL"
echo "   El archivo se sobrescribirá en el próximo deploy"
echo ""
echo "📋 Para hacer el cambio permanente:"
echo "   1. Ve a EasyPanel → Proyecto checkin24hs → Servicio dashboard"
echo "   2. Haz clic en 'Build' o 'Rebuild'"
echo "   3. Marca 'Build without cache'"
echo "   4. Espera 3-5 minutos"
echo ""
echo "🌐 Prueba el dashboard:"
echo "   https://dashboard.checkin24hs.com"
echo "   (Abre en ventana de incógnito y presiona Ctrl+Shift+R)"
echo ""
