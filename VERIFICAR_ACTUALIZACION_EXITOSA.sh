#!/bin/bash
# Script para verificar que la actualización del dashboard fue exitosa

echo "=========================================="
echo "✅ Verificando Actualización del Dashboard"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar tamaño del archivo
echo "1️⃣ Verificando archivo en el contenedor..."
FILE_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
echo "   Tamaño: $FILE_SIZE bytes ($FILE_SIZE_MB MB)"
echo ""

# 2. Verificar BUILD_TIMESTAMP
echo "2️⃣ Verificando BUILD_TIMESTAMP..."
BUILD_TS=$(docker exec "$CONTAINER_ID" grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")

if [ ! -z "$BUILD_TS" ]; then
    BUILD_DATE=$(echo "$BUILD_TS" | cut -d'T' -f1)
    BUILD_TIME=$(echo "$BUILD_TS" | cut -d'T' -f2 | cut -d'Z' -f1)
    TODAY_DATE=$(date +%Y-%m-%d)
    
    echo "   ✅ BUILD_TIMESTAMP encontrado: $BUILD_DATE $BUILD_TIME"
    
    if [ "$BUILD_DATE" = "$TODAY_DATE" ]; then
        echo "   ✅ Build es de HOY ($BUILD_DATE)"
    else
        echo "   ⚠️ Build es de fecha anterior ($BUILD_DATE)"
    fi
else
    echo "   ❌ No se encontró BUILD_TIMESTAMP"
fi

echo ""

# 3. Verificar DASHBOARD_VERSION
echo "3️⃣ Verificando DASHBOARD_VERSION..."
VERSION=$(docker exec "$CONTAINER_ID" grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")

if [ ! -z "$VERSION" ]; then
    echo "   ✅ DASHBOARD_VERSION: $VERSION"
else
    echo "   ❌ No se encontró DASHBOARD_VERSION"
fi

echo ""

# 4. Verificar UTF-8 (caracteres especiales)
echo "4️⃣ Verificando codificación UTF-8..."
if docker exec "$CONTAINER_ID" grep -q "VERSIÓN:" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ UTF-8 CORRECTO (tiene 'VERSIÓN' con tilde)"
elif docker exec "$CONTAINER_ID" grep -q "VERSI?N:" /app/dashboard.html 2>/dev/null; then
    echo "   ❌ UTF-8 INCORRECTO (tiene 'VERSI?N' con signo de interrogación)"
else
    echo "   ⚠️ No se pudo verificar UTF-8"
fi

echo ""

# 5. Verificar que el servidor responde
echo "5️⃣ Verificando que el servidor responde..."
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
    echo "   ✅ Servidor responde correctamente (HTTP 200)"
else
    echo "   ⚠️ El servidor puede necesitar reinicio"
    echo "   Ejecuta: docker service update --force checkin24hs_dashboard"
fi

echo ""

# 6. Verificar permisos
echo "6️⃣ Verificando permisos..."
PERMISSIONS=$(docker exec "$CONTAINER_ID" ls -l /app/dashboard.html 2>/dev/null | awk '{print $1, $3, $4}')
echo "   Permisos: $PERMISSIONS"

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ ! -z "$BUILD_TS" ] && [ ! -z "$VERSION" ]; then
    echo "✅ Dashboard actualizado correctamente"
    echo ""
    echo "📊 Información:"
    echo "   - Versión: $VERSION"
    echo "   - Build: $BUILD_TS"
    echo "   - Tamaño: $FILE_SIZE_MB MB"
    echo ""
    echo "🌐 Prueba el dashboard:"
    echo "   https://dashboard.checkin24hs.com"
    echo ""
    echo "   ⚠️ IMPORTANTE:"
    echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
    echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
    echo "   3. Verifica que los caracteres especiales se muestren correctamente"
    echo ""
    echo "   Si aún ves la versión antigua, limpia la caché del navegador"
else
    echo "⚠️ La actualización puede no estar completa"
    echo "   Verifica los errores arriba"
fi

echo ""
