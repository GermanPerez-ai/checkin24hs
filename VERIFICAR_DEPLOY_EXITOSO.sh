#!/bin/bash
# Script para verificar que el deploy fue exitoso

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR DEPLOY EXITOSO"
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

echo "=== 2. Verificar Build Number ==="
BUILD_NUMBER=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrado")
BUILD_TIMESTAMP=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrado")
echo "Version: $VERSION"
echo "Build Number: #$BUILD_NUMBER"
echo "Build Timestamp: $BUILD_TIMESTAMP"
if [ "$BUILD_NUMBER" = "5" ]; then
    echo "✅ OK: Build Number correcto (#5)"
else
    echo "❌ ERROR: Build Number incorrecto (esperado: #5, encontrado: #$BUILD_NUMBER)"
fi
echo ""

echo "=== 3. Verificar Display de Versión ==="
if docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "✅ OK: Display de versión encontrado"
    docker exec "$CONTAINER" grep -A 3 "version-display" /app/dashboard.html | head -4
else
    echo "❌ ERROR: Display de versión NO encontrado"
fi
echo ""

echo "=== 4. Verificar JavaScript de versión ==="
if docker exec "$CONTAINER" grep -q "version-numberEl" /app/dashboard.html; then
    echo "✅ OK: JavaScript de versión encontrado"
else
    echo "❌ ERROR: JavaScript de versión NO encontrado"
fi
echo ""

echo "=== 5. Verificar desde HTTP ==="
sleep 3
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
HTTP_BUILD=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
if [ "$HTTP_BUILD" = "5" ]; then
    echo "✅ OK: HTTP muestra Build #5"
else
    echo "⚠️ ADVERTENCIA: HTTP muestra Build #$HTTP_BUILD"
    echo "   Puede ser caché del navegador. Prueba con Ctrl+F5"
fi
echo ""

echo "=== 6. Verificar labels de Traefik ==="
TRAEFIK_COUNT=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -c traefik || echo "0")
if [ "$TRAEFIK_COUNT" -gt 0 ]; then
    echo "✅ OK: Labels de Traefik encontradas ($TRAEFIK_COUNT labels)"
else
    echo "⚠️ ADVERTENCIA: No se encontraron labels de Traefik"
    echo "   Si da 404, ejecuta: bash REAPLICAR_TRAEFIK_LABELS.sh"
fi
echo ""

echo "=========================================="
if [ "$BUILD_NUMBER" = "5" ] && docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "✅ DEPLOY EXITOSO"
    echo ""
    echo "El display de versión debería aparecer en el sidebar"
    echo "debajo de 'Checkin24hs Admin' mostrando:"
    echo "  - v$VERSION"
    echo "  - Build #$BUILD_NUMBER"
    echo ""
    echo "Si no aparece, recarga con Ctrl+F5"
else
    echo "❌ DEPLOY INCOMPLETO"
fi
echo "=========================================="
echo ""
