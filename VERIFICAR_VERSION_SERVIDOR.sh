#!/bin/bash
# Verificar versión del dashboard en el servidor

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

echo "=== 2. Verificar archivo dashboard.html en contenedor ==="
if docker exec "$CONTAINER" test -f /app/dashboard.html; then
    echo "✅ Archivo encontrado: /app/dashboard.html"
else
    echo "❌ Archivo no encontrado"
    exit 1
fi
echo ""

echo "=== 3. Extraer versión del archivo ==="
VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html | grep -oP "'[^']+'" | tr -d "'" || echo "No encontrada")
BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" /app/dashboard.html | grep -oP "'[^']+'" | tr -d "'" || echo "No encontrada")

echo "Versión: $VERSION"
echo "Build: $BUILD"
echo ""

echo "=== 4. Verificar versión desde HTTP ==="
HTTP_VERSION=$(curl -s "http://$DOMAIN" | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
HTTP_BUILD=$(curl -s "http://$DOMAIN" | grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")

echo "Versión HTTP: $HTTP_VERSION"
echo "Build HTTP: $HTTP_BUILD"
echo ""

echo "=== 5. Comparar versiones ==="
if [ "$VERSION" = "$HTTP_VERSION" ] && [ "$BUILD" = "$HTTP_BUILD" ]; then
    echo "✅ Versiones coinciden"
else
    echo "⚠️  Versiones no coinciden (puede ser caché)"
fi
echo ""

echo "=== 6. Verificar correcciones aplicadas ==="
CORRECCIONES=$(docker exec "$CONTAINER" grep -c "Mes/Año\|Ubicación\|¿Cómo\|Confirmación\|Estadía" /app/dashboard.html 2>/dev/null || echo "0")
echo "Correcciones encontradas: $CORRECCIONES"
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
