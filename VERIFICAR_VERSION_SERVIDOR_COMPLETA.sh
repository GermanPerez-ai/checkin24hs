#!/bin/bash
# Verificar versión completa del dashboard en el servidor

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔍 VERIFICAR VERSIÓN EN SERVIDOR"
echo "=========================================="
echo ""

echo "=== 1. Obtener contenedor activo ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi
echo "✅ Contenedor: $CONTAINER"
echo ""

echo "=== 2. Extraer versión del archivo en contenedor ==="
VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
BUILD_NUMBER=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrada")
BUILD_TIMESTAMP=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")

echo "Versión: $VERSION"
echo "Build Number: #$BUILD_NUMBER"
echo "Build Timestamp: $BUILD_TIMESTAMP"
echo ""

echo "=== 3. Verificar versión desde HTTP ==="
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
HTTP_BUILD_NUMBER=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
HTTP_BUILD_TIMESTAMP=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")

echo "Versión HTTP: $HTTP_VERSION"
echo "Build Number HTTP: #$HTTP_BUILD_NUMBER"
echo "Build Timestamp HTTP: $HTTP_BUILD_TIMESTAMP"
echo ""

echo "=== 4. Comparar versiones ==="
if [ "$VERSION" = "$HTTP_VERSION" ] && [ "$BUILD_NUMBER" = "$HTTP_BUILD_NUMBER" ]; then
    echo "✅ Versiones coinciden entre contenedor y HTTP"
else
    echo "⚠️  Versiones no coinciden (puede ser caché del navegador)"
    echo "   Recarga la página con Ctrl+F5"
fi
echo ""

echo "=== 5. Verificar display de versión en HTML ==="
HAS_VERSION_DISPLAY=$(docker exec "$CONTAINER" grep -c "version-display\|version-number\|build-number" /app/dashboard.html 2>/dev/null || echo "0")
if [ "$HAS_VERSION_DISPLAY" -gt "0" ]; then
    echo "✅ Display de versión encontrado en HTML ($HAS_VERSION_DISPLAY ocurrencias)"
else
    echo "❌ Display de versión NO encontrado"
fi
echo ""

echo "=== 6. Verificar correcciones aplicadas ==="
CORRECCIONES=$(docker exec "$CONTAINER" grep -c "Mes/Año\|Ubicación\|¿Cómo\|Confirmación\|Estadía" /app/dashboard.html 2>/dev/null || echo "0")
echo "Correcciones encontradas: $CORRECCIONES"
if [ "$CORRECCIONES" -gt "0" ]; then
    echo "✅ Correcciones aplicadas"
else
    echo "⚠️  No se encontraron correcciones"
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "📋 RESUMEN:"
echo "   Versión: $VERSION"
echo "   Build: #$BUILD_NUMBER"
echo "   Timestamp: $BUILD_TIMESTAMP"
echo ""
echo "💡 La versión debe aparecer en el sidebar debajo de 'Checkin24hs Admin'"
echo ""
