#!/bin/bash
# Script para actualizar dashboard.html y reiniciar el proceso Node.js

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "ACTUALIZAR Y REINICIAR PROCESO"
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
BUILD_CHECK=$(grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /tmp/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1)
echo "Build Number en archivo: #$BUILD_CHECK"
if [ "$BUILD_CHECK" != "5" ]; then
    echo "❌ ERROR: El archivo NO tiene Build #5"
    exit 1
fi
echo "✅ Archivo correcto descargado"
echo ""

echo "=== 3. Detener proceso Node.js en el contenedor ==="
docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || echo "   Proceso no encontrado (puede estar corriendo con otro nombre)"
sleep 2
echo "✅ Proceso detenido"
echo ""

echo "=== 4. Copiar archivo al contenedor ==="
docker cp /tmp/dashboard.html "$CONTAINER:/app/dashboard.html" 2>&1 | grep -v "device or resource busy" | grep -v "Error response" || true
sleep 1
echo "✅ Archivo copiado"
echo ""

echo "=== 5. Verificar que el archivo se copió ==="
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number en contenedor: #$CONTAINER_BUILD"
if [ "$CONTAINER_BUILD" != "5" ]; then
    echo "❌ ERROR: El archivo NO se actualizó correctamente"
    echo "   El proceso Node.js se reiniciará automáticamente por Docker Swarm"
    echo "   Espera 10 segundos y verifica de nuevo"
    exit 1
fi
echo "✅ Archivo actualizado correctamente"
echo ""

echo "=== 6. El proceso Node.js se reiniciará automáticamente ==="
echo "   Esperando 5 segundos..."
sleep 5
echo ""

echo "=== 7. Verificar desde HTTP ==="
sleep 3
HTTP_BUILD=$(curl -s "http://dashboard.checkin24hs.com" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
HTTP_VERSION=$(curl -s "http://dashboard.checkin24hs.com" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
if [ "$HTTP_BUILD" = "5" ]; then
    echo "✅ OK: HTTP muestra Build #5"
else
    echo "⚠️ ADVERTENCIA: HTTP muestra Build #$HTTP_BUILD"
    echo "   Espera 10 segundos más y prueba de nuevo"
    sleep 10
    HTTP_BUILD=$(curl -s "http://dashboard.checkin24hs.com" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
    if [ "$HTTP_BUILD" = "5" ]; then
        echo "✅ OK: HTTP ahora muestra Build #5"
    else
        echo "⚠️ HTTP aún muestra Build #$HTTP_BUILD"
        echo "   Prueba con Ctrl+F5 en el navegador"
    fi
fi
echo ""

echo "=========================================="
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "✅ ARCHIVO ACTUALIZADO Y PROCESO REINICIADO"
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
