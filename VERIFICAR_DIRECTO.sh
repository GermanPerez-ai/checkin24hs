#!/bin/bash
# Script para verificar directamente el archivo en el contenedor

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "VERIFICACION DIRECTA DEL ARCHIVO"
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

echo "=== 2. Verificar líneas específicas del archivo ==="
echo "Línea 10-12 del archivo:"
docker exec "$CONTAINER" sed -n '10,12p' /app/dashboard.html
echo ""

echo "=== 3. Buscar DASHBOARD_BUILD_NUMBER directamente ==="
docker exec "$CONTAINER" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html | head -1
echo ""

echo "=== 4. Buscar version-display directamente ==="
docker exec "$CONTAINER" grep -c "version-display" /app/dashboard.html && echo "✅ Encontrado" || echo "❌ NO encontrado"
echo ""

echo "=== 5. Verificar tamaño del archivo ==="
SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
echo "Tamaño: $SIZE bytes"
echo ""

echo "=== 6. Comparar con archivo local ==="
if [ -f "/tmp/dashboard.html" ]; then
    LOCAL_SIZE=$(stat -c%s /tmp/dashboard.html 2>/dev/null || echo "0")
    echo "Tamaño local: $LOCAL_SIZE bytes"
    echo "Tamaño contenedor: $SIZE bytes"
    if [ "$LOCAL_SIZE" = "$SIZE" ]; then
        echo "✅ Tamaños coinciden"
    else
        echo "⚠️ Tamaños NO coinciden (diferencia: $((LOCAL_SIZE - SIZE)) bytes)"
    fi
fi
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
