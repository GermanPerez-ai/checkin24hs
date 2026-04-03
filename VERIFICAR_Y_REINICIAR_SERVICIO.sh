#!/bin/bash
# Script para verificar que el contenedor lee el archivo actualizado y reiniciar si es necesario

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR Y REINICIAR SERVICIO"
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

echo "=== 2. Verificar tamaño del archivo en contenedor ==="
CONTAINER_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
SERVER_SIZE=$(stat -c%s /root/checkin24hs/dashboard.html 2>/dev/null || echo "0")
echo "Tamaño en servidor: $SERVER_SIZE bytes"
echo "Tamaño en contenedor: $CONTAINER_SIZE bytes"
if [ "$CONTAINER_SIZE" -eq "$SERVER_SIZE" ] && [ "$SERVER_SIZE" -gt 1000000 ]; then
    echo "✅ OK: Archivo correcto en contenedor"
else
    echo "⚠️ ADVERTENCIA: Tamaños no coinciden o archivo muy pequeño"
fi
echo ""

echo "=== 3. Verificar Build Number en contenedor ==="
BUILD_NUMBER=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number en contenedor: #$BUILD_NUMBER"
if [ "$BUILD_NUMBER" = "5" ]; then
    echo "✅ OK: Contenedor tiene Build #5"
else
    echo "❌ ERROR: Contenedor NO tiene Build #5"
fi
echo ""

echo "=== 4. Reiniciar servicio para forzar lectura del archivo ==="
echo "   Esto asegura que Node.js lea el archivo actualizado..."
docker service update --force "$SERVICE_NAME"
if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
    echo "   Esperando 15 segundos para que el servicio se inicie..."
    sleep 15
else
    echo "❌ ERROR: No se pudo reiniciar el servicio"
    exit 1
fi
echo ""

echo "=== 5. Buscar nuevo contenedor ==="
NEW_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$NEW_CONTAINER" ]; then
    NEW_CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$NEW_CONTAINER" ]; then
    echo "ERROR: No se encontro nuevo contenedor"
    exit 1
fi
echo "OK: Nuevo contenedor: $NEW_CONTAINER"
echo ""

echo "=== 6. Verificar Build Number en nuevo contenedor ==="
sleep 5
NEW_BUILD=$(docker exec "$NEW_CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
NEW_VERSION=$(docker exec "$NEW_CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrado")
echo "Version: $NEW_VERSION"
echo "Build Number: #$NEW_BUILD"
if [ "$NEW_BUILD" = "5" ]; then
    echo "✅ OK: Nuevo contenedor tiene Build #5"
else
    echo "❌ ERROR: Nuevo contenedor NO tiene Build #5"
fi
echo ""

echo "=== 7. Verificar desde HTTP (esperando 10 segundos más) ==="
sleep 10
HTTP_BUILD=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
if [ "$HTTP_BUILD" = "5" ]; then
    echo "✅ OK: HTTP muestra Build #5"
    echo ""
    echo "=========================================="
    echo "✅ SERVICIO ACTUALIZADO CORRECTAMENTE"
    echo "=========================================="
    echo ""
    echo "El display de versión debería aparecer en el sidebar"
    echo "debajo de 'Checkin24hs Admin' mostrando:"
    echo "  - v$HTTP_VERSION"
    echo "  - Build #$HTTP_BUILD"
    echo ""
    echo "Si no aparece, recarga la página con Ctrl+F5"
else
    echo "⚠️ ADVERTENCIA: HTTP muestra Build #$HTTP_BUILD"
    echo "   Espera 30 segundos más y prueba de nuevo"
    echo "   O recarga la página con Ctrl+F5"
fi
echo ""
