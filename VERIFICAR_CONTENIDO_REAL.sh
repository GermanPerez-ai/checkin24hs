#!/bin/bash
# Script para verificar el contenido real del archivo en el contenedor

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "VERIFICAR CONTENIDO REAL DEL ARCHIVO"
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

echo "=== 2. Verificar líneas 1-15 del archivo ==="
docker exec "$CONTAINER" head -15 /app/dashboard.html
echo ""

echo "=== 3. Buscar todas las ocurrencias de DASHBOARD ==="
docker exec "$CONTAINER" grep -i "DASHBOARD" /app/dashboard.html | head -5
echo ""

echo "=== 4. Buscar BUILD ==="
docker exec "$CONTAINER" grep -i "BUILD" /app/dashboard.html | head -5
echo ""

echo "=== 5. Buscar version-display ==="
docker exec "$CONTAINER" grep -i "version-display" /app/dashboard.html | head -2
echo ""

echo "=== 6. Verificar tamaño del archivo ==="
SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
echo "Tamaño: $SIZE bytes"
echo ""

echo "=== 7. Comparar con archivo en GitHub (primeras 15 líneas) ==="
curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html | head -15
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
