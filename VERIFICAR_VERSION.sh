#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR VERSION EN SERVIDOR"
echo "=========================================="
echo ""

echo "=== 1. Obtener contenedor activo ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor activo"
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 2. Extraer version del archivo en contenedor ==="
VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
BUILD_NUMBER=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrada")
BUILD_TIMESTAMP=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")

echo "Version: $VERSION"
echo "Build Number: #$BUILD_NUMBER"
echo "Build Timestamp: $BUILD_TIMESTAMP"
echo ""

echo "=== 3. Verificar version desde HTTP ==="
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
HTTP_BUILD_NUMBER=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")

echo "Version HTTP: $HTTP_VERSION"
echo "Build Number HTTP: #$HTTP_BUILD_NUMBER"
echo ""

echo "=== 4. Comparar versiones ==="
if [ "$VERSION" = "$HTTP_VERSION" ] && [ "$BUILD_NUMBER" = "$HTTP_BUILD_NUMBER" ]; then
    echo "OK: Versiones coinciden entre contenedor y HTTP"
else
    echo "ADVERTENCIA: Versiones no coinciden (puede ser cache del navegador)"
    echo "   Recarga la pagina con Ctrl+F5"
fi
echo ""

echo "=== 5. Verificar display de version en HTML ==="
HAS_VERSION_DISPLAY=$(docker exec "$CONTAINER" grep -c "version-display\|version-number\|build-number" /app/dashboard.html 2>/dev/null || echo "0")
if [ "$HAS_VERSION_DISPLAY" -gt "0" ]; then
    echo "OK: Display de version encontrado en HTML ($HAS_VERSION_DISPLAY ocurrencias)"
else
    echo "ERROR: Display de version NO encontrado"
fi
echo ""

echo "=== 6. Verificar correcciones aplicadas ==="
CORRECCIONES=$(docker exec "$CONTAINER" grep -c "Mes/Año\|Ubicación\|¿Cómo\|Confirmación\|Estadía" /app/dashboard.html 2>/dev/null || echo "0")
echo "Correcciones encontradas: $CORRECCIONES"
if [ "$CORRECCIONES" -gt "0" ]; then
    echo "OK: Correcciones aplicadas"
else
    echo "ADVERTENCIA: No se encontraron correcciones"
fi
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
echo ""
echo "RESUMEN:"
echo "   Version: $VERSION"
echo "   Build: #$BUILD_NUMBER"
echo "   Timestamp: $BUILD_TIMESTAMP"
echo ""
echo "La version debe aparecer en el sidebar debajo de 'Checkin24hs Admin'"
echo ""
