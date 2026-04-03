#!/bin/bash
# Script mejorado para verificar HTTP y HTTPS, y corregir detección de Build Number

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR COMPLETO (HTTP Y HTTPS)"
echo "=========================================="
echo ""

echo "=== 1. Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor"
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 2. Verificar archivo directamente (método robusto) ==="
echo "Extrayendo Build Number con múltiples métodos..."
BUILD_LINE=$(docker exec "$CONTAINER" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -1)
echo "Línea encontrada: $BUILD_LINE"
BUILD_NUMBER=$(echo "$BUILD_LINE" | grep -oE "[0-9]+" | head -1 || echo "")
echo "Build Number extraído: #$BUILD_NUMBER"

# Extraer versión
VERSION_LINE=$(docker exec "$CONTAINER" grep "DASHBOARD_VERSION = " /app/dashboard.html 2>/dev/null | head -1)
VERSION=$(echo "$VERSION_LINE" | grep -oE "'[^']+'" | head -1 | tr -d "'" || echo "")
echo "Version extraída: $VERSION"
echo ""

if [ "$BUILD_NUMBER" = "5" ]; then
    echo "✅ OK: Contenedor tiene Build #5"
else
    echo "❌ ERROR: Contenedor NO tiene Build #5 (encontrado: #$BUILD_NUMBER)"
    echo ""
    echo "Mostrando líneas relevantes del archivo:"
    docker exec "$CONTAINER" grep -A 2 -B 2 "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -5
    echo ""
fi
echo ""

echo "=== 3. Verificar desde HTTP ==="
sleep 2
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" 2>/dev/null)
HTTP_RESPONSE=$(curl -s "http://$DOMAIN" 2>/dev/null)
echo "HTTP Status: $HTTP_STATUS"

if [ -n "$HTTP_RESPONSE" ]; then
    HTTP_BUILD_LINE=$(echo "$HTTP_RESPONSE" | grep "DASHBOARD_BUILD_NUMBER" | head -1)
    HTTP_BUILD=$(echo "$HTTP_BUILD_LINE" | grep -oE "[0-9]+" | head -1 || echo "")
    HTTP_VERSION_LINE=$(echo "$HTTP_RESPONSE" | grep "DASHBOARD_VERSION = " | head -1)
    HTTP_VERSION=$(echo "$HTTP_VERSION_LINE" | grep -oE "'[^']+'" | head -1 | tr -d "'" || echo "")
    echo "Version HTTP: $HTTP_VERSION"
    echo "Build HTTP: #$HTTP_BUILD"
    if [ "$HTTP_BUILD" = "5" ]; then
        echo "✅ OK: HTTP muestra Build #5"
    else
        echo "⚠️ ADVERTENCIA: HTTP muestra Build #$HTTP_BUILD"
    fi
else
    echo "❌ ERROR: No se pudo obtener respuesta HTTP"
    HTTP_VERSION=""
    HTTP_BUILD=""
fi
echo ""

echo "=== 4. Verificar desde HTTPS ==="
sleep 2
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null)
HTTPS_RESPONSE=$(curl -s "https://$DOMAIN" 2>/dev/null)
echo "HTTPS Status: $HTTPS_STATUS"

if [ -n "$HTTPS_RESPONSE" ]; then
    HTTPS_BUILD_LINE=$(echo "$HTTPS_RESPONSE" | grep "DASHBOARD_BUILD_NUMBER" | head -1)
    HTTPS_BUILD=$(echo "$HTTPS_BUILD_LINE" | grep -oE "[0-9]+" | head -1 || echo "")
    HTTPS_VERSION_LINE=$(echo "$HTTPS_RESPONSE" | grep "DASHBOARD_VERSION = " | head -1)
    HTTPS_VERSION=$(echo "$HTTPS_VERSION_LINE" | grep -oE "'[^']+'" | head -1 | tr -d "'" || echo "")
    echo "Version HTTPS: $HTTPS_VERSION"
    echo "Build HTTPS: #$HTTPS_BUILD"
    if [ "$HTTPS_BUILD" = "5" ]; then
        echo "✅ OK: HTTPS muestra Build #5"
    else
        echo "⚠️ ADVERTENCIA: HTTPS muestra Build #$HTTPS_BUILD"
    fi
else
    echo "❌ ERROR: No se pudo obtener respuesta HTTPS"
    HTTPS_VERSION=""
    HTTPS_BUILD=""
fi
echo ""

echo "=== 5. Verificar display de versión en HTML ==="
if docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html 2>/dev/null; then
    echo "✅ OK: Display de versión encontrado en archivo"
else
    echo "❌ ERROR: Display de versión NO encontrado"
fi

# Verificar en HTTP
if [ -n "$HTTP_RESPONSE" ] && echo "$HTTP_RESPONSE" | grep -q "version-display" 2>/dev/null; then
    echo "✅ OK: Display de versión encontrado en HTTP"
else
    echo "⚠️ ADVERTENCIA: Display de versión NO encontrado en HTTP"
fi

# Verificar en HTTPS
if [ -n "$HTTPS_RESPONSE" ] && echo "$HTTPS_RESPONSE" | grep -q "version-display" 2>/dev/null; then
    echo "✅ OK: Display de versión encontrado en HTTPS"
else
    echo "⚠️ ADVERTENCIA: Display de versión NO encontrado en HTTPS"
fi
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo "Contenedor:"
echo "  - Version: $VERSION"
echo "  - Build: #$BUILD_NUMBER"
echo ""
echo "HTTP (http://$DOMAIN):"
echo "  - Status: $HTTP_STATUS"
echo "  - Version: $HTTP_VERSION"
echo "  - Build: #$HTTP_BUILD"
echo ""
echo "HTTPS (https://$DOMAIN):"
echo "  - Status: $HTTPS_STATUS"
echo "  - Version: $HTTPS_VERSION"
echo "  - Build: #$HTTPS_BUILD"
echo ""

if [ "$BUILD_NUMBER" = "5" ] && [ "$HTTP_BUILD" = "5" ] && [ "$HTTPS_BUILD" = "5" ]; then
    echo "✅ TODO CORRECTO: Build #5 en contenedor, HTTP y HTTPS"
    echo ""
    echo "El display de versión debería aparecer en el sidebar"
    echo "debajo de 'Checkin24hs Admin' mostrando:"
    echo "  - v$VERSION"
    echo "  - Build #5"
    echo ""
    echo "Si no aparece, recarga la página con Ctrl+F5"
elif [ "$BUILD_NUMBER" = "5" ]; then
    echo "⚠️ ADVERTENCIA: Contenedor tiene Build #5, pero HTTP/HTTPS no"
    echo "   Esto puede ser caché del navegador o de Traefik"
    echo "   Espera 1-2 minutos y recarga con Ctrl+F5"
else
    echo "❌ PROBLEMA: El contenedor NO tiene Build #5"
    echo "   El archivo en el servidor podría estar desactualizado"
    echo "   Ejecuta: bash ACTUALIZAR_ARCHIVO_SERVIDOR.sh"
fi
echo "=========================================="
echo ""
