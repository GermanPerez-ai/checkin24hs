#!/bin/bash
# Script para actualizar dashboard.html en el contenedor actual

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "ACTUALIZAR ARCHIVO EN CONTENEDOR"
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
    echo "✅ Archivo descargado correctamente"
    SIZE=$(stat -c%s /tmp/dashboard.html 2>/dev/null || echo "0")
    echo "   Tamaño: $SIZE bytes"
else
    echo "❌ ERROR: No se pudo descargar el archivo"
    exit 1
fi
echo ""

echo "=== 3. Verificar que el archivo descargado tiene Build #5 ==="
BUILD_NUMBER=$(grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /tmp/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number en archivo descargado: #$BUILD_NUMBER"
if [ "$BUILD_NUMBER" != "5" ]; then
    echo "❌ ERROR: El archivo descargado NO tiene Build #5"
    exit 1
fi
echo "✅ OK: Archivo tiene Build #5"
echo ""

echo "=== 4. Copiar archivo al contenedor ==="
docker cp /tmp/dashboard.html "$CONTAINER:/app/dashboard.html"
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado al contenedor"
else
    echo "❌ ERROR: No se pudo copiar el archivo"
    exit 1
fi
echo ""

echo "=== 5. Verificar que se copió correctamente ==="
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number en contenedor: #$CONTAINER_BUILD"
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "✅ OK: Archivo actualizado correctamente en el contenedor"
else
    echo "❌ ERROR: El archivo en el contenedor NO tiene Build #5"
    exit 1
fi
echo ""

echo "=== 6. Esperar 3 segundos y verificar desde HTTP ==="
sleep 3
HTTP_BUILD=$(curl -s "http://dashboard.checkin24hs.com" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Build HTTP: #$HTTP_BUILD"
if [ "$HTTP_BUILD" = "5" ]; then
    echo "✅ OK: HTTP muestra Build #5"
else
    echo "⚠️ ADVERTENCIA: HTTP muestra Build #$HTTP_BUILD"
    echo "   Puede ser caché del navegador. Prueba con Ctrl+F5"
fi
echo ""

echo "=========================================="
echo "✅ ARCHIVO ACTUALIZADO EN CONTENEDOR"
echo "=========================================="
echo ""
echo "IMPORTANTE:"
echo "- Esta es una solución TEMPORAL"
echo "- Los cambios se perderán si el servicio se reinicia o se hace deploy"
echo "- Para solución PERMANENTE, haz un nuevo deploy desde EasyPanel"
echo "  que use el commit más reciente (0c83d6a o posterior)"
echo ""
