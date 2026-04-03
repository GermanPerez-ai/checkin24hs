#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR VERSION COMPLETA"
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

echo "=== 2. Version en contenedor ==="
docker exec "$CONTAINER" grep -E "DASHBOARD_VERSION|DASHBOARD_BUILD_NUMBER|DASHBOARD_BUILD" /app/dashboard.html | head -3
echo ""

echo "=== 3. Display de version en HTML ==="
if docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "OK: Display encontrado"
    docker exec "$CONTAINER" grep -A 3 "version-display" /app/dashboard.html | head -4
else
    echo "ERROR: Display NO encontrado"
fi
echo ""

echo "=== 4. JavaScript que actualiza version ==="
if docker exec "$CONTAINER" grep -q "version-number" /app/dashboard.html; then
    echo "OK: JavaScript encontrado"
    docker exec "$CONTAINER" grep -B 2 -A 5 "version-numberEl" /app/dashboard.html | head -8
else
    echo "ERROR: JavaScript NO encontrado"
fi
echo ""

echo "=== 5. Version desde HTTP ==="
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
HTTP_BUILD=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
echo ""

echo "=== 6. Comparar versiones ==="
CONTAINER_VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Version contenedor: $CONTAINER_VERSION"
echo "Build contenedor: #$CONTAINER_BUILD"
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "OK: Version actualizada (Build #5)"
else
    echo "ADVERTENCIA: Version no es la mas reciente (esperado: #5, encontrado: #$CONTAINER_BUILD)"
fi
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
