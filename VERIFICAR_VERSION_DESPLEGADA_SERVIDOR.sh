#!/bin/bash
# Script para verificar qué versión está realmente desplegada en el servidor

echo "=========================================="
echo "🔍 Verificando versión desplegada en servidor"
echo "=========================================="
echo ""

# 1. Obtener contenedor del dashboard
CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER"
echo ""

# 2. Verificar BUILD_TIMESTAMP en el contenedor
echo "📋 Verificando BUILD_TIMESTAMP en el contenedor..."
BUILD_TS=$(docker exec "$CONTAINER" grep -oP "window\.BUILD_TIMESTAMP = '\K[^']+" /app/dashboard.html 2>/dev/null | head -1)

if [ -z "$BUILD_TS" ]; then
    echo "⚠️ No se encontró BUILD_TIMESTAMP en el contenedor"
else
    echo "✅ BUILD_TIMESTAMP en contenedor: $BUILD_TS"
fi

# 3. Verificar DASHBOARD_VERSION
echo ""
echo "📋 Verificando DASHBOARD_VERSION en el contenedor..."
VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION = '\K[^']+" /app/dashboard.html 2>/dev/null | head -1)

if [ -z "$VERSION" ]; then
    echo "⚠️ No se encontró DASHBOARD_VERSION en el contenedor"
else
    echo "✅ DASHBOARD_VERSION en contenedor: $VERSION"
fi

# 4. Verificar fecha de modificación del archivo
echo ""
echo "📋 Verificando fecha de modificación del archivo..."
FILE_DATE=$(docker exec "$CONTAINER" stat -c %y /app/dashboard.html 2>/dev/null | cut -d' ' -f1)

if [ -z "$FILE_DATE" ]; then
    echo "⚠️ No se pudo obtener la fecha de modificación"
else
    echo "✅ Fecha de modificación: $FILE_DATE"
fi

# 5. Verificar endpoint /api/version
echo ""
echo "📋 Verificando endpoint /api/version..."
API_RESPONSE=$(docker exec "$CONTAINER" curl -s http://localhost:3000/api/version 2>/dev/null)

if [ -z "$API_RESPONSE" ]; then
    echo "⚠️ No se pudo obtener respuesta del endpoint /api/version"
else
    echo "✅ Respuesta del endpoint:"
    echo "$API_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$API_RESPONSE"
fi

# 6. Comparar con versión esperada
echo ""
echo "=========================================="
echo "📊 Resumen"
echo "=========================================="
echo ""

EXPECTED_TS="2026-01-12T19:41:17Z"
EXPECTED_VERSION="2.1.0"

echo "Versión esperada: $EXPECTED_VERSION"
echo "Timestamp esperado: $EXPECTED_TS"
echo ""
echo "Versión en contenedor: ${VERSION:-'NO ENCONTRADA'}"
echo "Timestamp en contenedor: ${BUILD_TS:-'NO ENCONTRADO'}"
echo ""

if [ "$VERSION" = "$EXPECTED_VERSION" ] && [ "$BUILD_TS" = "$EXPECTED_TS" ]; then
    echo "✅ El contenedor tiene la versión CORRECTA"
    echo ""
    echo "💡 Si el navegador muestra versión antigua:"
    echo "   1. Limpia la caché del navegador (Ctrl+Shift+Delete)"
    echo "   2. Usa modo incógnito (Ctrl+Shift+N)"
    echo "   3. Abre DevTools (F12) → Network → Marca 'Disable cache'"
    echo "   4. Recarga con Ctrl+Shift+R"
else
    echo "❌ El contenedor tiene una versión ANTIGUA"
    echo ""
    echo "💡 Solución:"
    echo "   1. Ve a EasyPanel"
    echo "   2. Haz clic en 'Deploy' o 'Redeploy'"
    echo "   3. Espera 3-5 minutos"
    echo "   4. Ejecuta este script de nuevo para verificar"
fi

echo ""
