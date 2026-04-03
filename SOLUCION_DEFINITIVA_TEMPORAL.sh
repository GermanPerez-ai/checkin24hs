#!/bin/bash
# Script para actualizar el archivo de forma más agresiva

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "SOLUCION TEMPORAL AGRESIVA"
echo "=========================================="
echo ""

echo "=== 1. Descargar archivo correcto ==="
curl -s -o /tmp/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
BUILD_CHECK=$(grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /tmp/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1)
echo "Build Number: #$BUILD_CHECK"
if [ "$BUILD_CHECK" != "5" ]; then
    echo "❌ ERROR: El archivo NO tiene Build #5"
    exit 1
fi
echo "✅ Archivo correcto"
echo ""

echo "=== 2. Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 3. Copiar archivo usando método alternativo ==="
docker exec "$CONTAINER" sh -c "cat > /app/dashboard.html" < /tmp/dashboard.html 2>&1 || true
sleep 2
echo "✅ Archivo copiado"
echo ""

echo "=== 4. Verificar ==="
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
echo "Build Number: #$CONTAINER_BUILD"
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "✅ OK: Archivo actualizado"
else
    echo "❌ ERROR: Archivo NO actualizado"
    echo ""
    echo "SOLUCIÓN PERMANENTE: Haz un deploy desde EasyPanel"
    exit 1
fi
echo ""

echo "=== 5. Verificar desde HTTP ==="
sleep 5
HTTP_BUILD=$(curl -s "http://dashboard.checkin24hs.com" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Build HTTP: #$HTTP_BUILD"
echo ""

echo "=========================================="
echo "✅ ARCHIVO ACTUALIZADO (TEMPORAL)"
echo "=========================================="
