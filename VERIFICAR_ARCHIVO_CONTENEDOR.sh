#!/bin/bash
# Script para verificar qué archivo dashboard.html está en el contenedor

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR ARCHIVO EN CONTENEDOR"
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

echo "=== 2. Verificar ruta del archivo en contenedor ==="
echo "Verificando si existe /app/dashboard.html:"
docker exec "$CONTAINER" test -f /app/dashboard.html && echo "OK: Archivo existe en /app/dashboard.html" || echo "ERROR: Archivo NO existe en /app/dashboard.html"
echo ""

echo "=== 3. Verificar tamaño del archivo ==="
SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
echo "Tamaño del archivo: $SIZE bytes"
echo ""

echo "=== 4. Verificar Build Number en contenedor ==="
BUILD_NUMBER=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number encontrado: #$BUILD_NUMBER"
if [ "$BUILD_NUMBER" = "5" ]; then
    echo "OK: Build Number correcto (#5)"
else
    echo "ERROR: Build Number incorrecto (esperado: #5, encontrado: #$BUILD_NUMBER)"
fi
echo ""

echo "=== 5. Verificar Display de Versión ==="
if docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "OK: Display de versión encontrado"
    docker exec "$CONTAINER" grep -A 3 "version-display" /app/dashboard.html | head -4
else
    echo "ERROR: Display de versión NO encontrado"
fi
echo ""

echo "=== 6. Verificar JavaScript de versión ==="
if docker exec "$CONTAINER" grep -q "version-numberEl" /app/dashboard.html; then
    echo "OK: JavaScript de versión encontrado"
else
    echo "ERROR: JavaScript de versión NO encontrado"
fi
echo ""

echo "=== 7. Verificar hash MD5 del archivo (primeras líneas) ==="
echo "Primeras 5 líneas del archivo:"
docker exec "$CONTAINER" head -5 /app/dashboard.html
echo ""

echo "=== 8. Verificar timestamp del archivo ==="
docker exec "$CONTAINER" stat /app/dashboard.html 2>/dev/null | grep -E "Modify|Change"
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
