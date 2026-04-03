#!/bin/bash

echo "=========================================="
echo "🔍 COMPARAR HEADER EN ARCHIVOS"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "=== 1. ARCHIVO LOCAL EN SERVIDOR ==="
echo "Primeras líneas del header:"
grep -A 12 'class="header"' dashboard.html | head -13
echo ""

echo "=== 2. ARCHIVO EN CONTENEDOR ==="
echo "Primeras líneas del header:"
docker exec "$CONTAINER" grep -A 12 'class="header"' /app/dashboard.html 2>/dev/null | head -13
echo ""

echo "=== 3. COMPARAR TAMAÑOS ==="
LOCAL_SIZE=$(wc -c < dashboard.html)
CONTAINER_SIZE=$(docker exec "$CONTAINER" wc -c < /app/dashboard.html 2>/dev/null)
echo "Archivo local: $LOCAL_SIZE bytes"
echo "Archivo contenedor: $CONTAINER_SIZE bytes"
if [ "$LOCAL_SIZE" = "$CONTAINER_SIZE" ]; then
    echo "✅ Los archivos tienen el mismo tamaño"
else
    echo "⚠️  Los archivos tienen tamaños diferentes"
fi
echo ""

echo "=== 4. VERIFICAR header-left ESPECÍFICAMENTE ==="
echo "Archivo local:"
grep -n "header-left" dashboard.html | head -3
echo ""
echo "Archivo contenedor:"
docker exec "$CONTAINER" grep -n "header-left" /app/dashboard.html 2>/dev/null | head -3
echo ""

echo "=========================================="
echo "✅ Comparación completada"
echo "=========================================="
