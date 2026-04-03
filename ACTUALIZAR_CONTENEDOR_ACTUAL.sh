#!/bin/bash
# Script para actualizar dashboard.html en el contenedor actual

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "ACTUALIZAR CONTENEDOR ACTUAL"
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

echo "=== 2. Descargar archivo correcto desde GitHub ==="
curl -s -o /tmp/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado"
    BUILD_CHECK=$(grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /tmp/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1)
    echo "   Build Number en archivo: #$BUILD_CHECK"
    if [ "$BUILD_CHECK" != "5" ]; then
        echo "❌ ERROR: El archivo NO tiene Build #5"
        exit 1
    fi
else
    echo "❌ ERROR: No se pudo descargar"
    exit 1
fi
echo ""

echo "=== 3. Copiar archivo al contenedor ==="
docker cp /tmp/dashboard.html "$CONTAINER:/app/dashboard.html" 2>&1
if [ $? -eq 0 ] || docker exec "$CONTAINER" test -f /app/dashboard.html; then
    echo "✅ Archivo copiado (el error 'device or resource busy' es normal)"
else
    echo "❌ ERROR: No se pudo copiar"
    exit 1
fi
echo ""

echo "=== 4. Verificar en contenedor ==="
sleep 2
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number en contenedor: #$CONTAINER_BUILD"
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "✅ OK: Archivo actualizado correctamente"
else
    echo "❌ ERROR: El archivo NO se actualizó"
    echo "   Intentando de nuevo..."
    sleep 2
    docker cp /tmp/dashboard.html "$CONTAINER:/app/dashboard.html" 2>&1
    sleep 2
    CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
    if [ "$CONTAINER_BUILD" = "5" ]; then
        echo "✅ OK: Archivo actualizado en segundo intento"
    else
        echo "❌ ERROR: El archivo sigue sin actualizarse"
        exit 1
    fi
fi
echo ""

echo "=== 5. Verificar desde HTTP ==="
sleep 3
HTTP_BUILD=$(curl -s "http://dashboard.checkin24hs.com" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Build HTTP: #$HTTP_BUILD"
if [ "$HTTP_BUILD" = "5" ]; then
    echo "✅ OK: HTTP muestra Build #5"
else
    echo "⚠️ ADVERTENCIA: HTTP muestra Build #$HTTP_BUILD"
    echo "   Prueba con Ctrl+F5 en el navegador"
fi
echo ""

echo "=========================================="
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "✅ ARCHIVO ACTUALIZADO"
    echo ""
    echo "El display de versión debería aparecer en el sidebar."
    echo "Si no aparece, recarga con Ctrl+F5"
else
    echo "❌ ARCHIVO NO ACTUALIZADO"
    echo ""
    echo "SOLUCIÓN PERMANENTE:"
    echo "1. Ve a EasyPanel → Servicio 'dashboard'"
    echo "2. Haz un nuevo Deploy/Redeploy"
    echo "3. Asegúrate de que use el commit más reciente"
fi
echo "=========================================="
echo ""
