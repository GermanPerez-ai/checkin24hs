#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR HEADER EN SERVIDOR"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar archivo local en servidor
echo "=== 1. ARCHIVO LOCAL EN SERVIDOR ==="
if grep -q "header-left" dashboard.html; then
    echo "✅ El archivo local tiene 'header-left'"
    grep -n "header-left" dashboard.html | head -3
else
    echo "❌ El archivo local NO tiene 'header-left'"
fi
echo ""

# 2. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
DASHBOARD_PATH="/app/dashboard.html"

echo "📦 Contenedor: $CONTAINER"
echo "📁 Ruta: $DASHBOARD_PATH"
echo ""

# 3. Verificar archivo en contenedor
echo "=== 2. ARCHIVO EN CONTENEDOR ==="
if docker exec "$CONTAINER" grep -q "header-left" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ El archivo en el contenedor tiene 'header-left'"
    docker exec "$CONTAINER" grep -n "header-left" "$DASHBOARD_PATH" 2>/dev/null | head -3
else
    echo "❌ El archivo en el contenedor NO tiene 'header-left'"
fi
echo ""

# 4. Ver estructura del header
echo "=== 3. ESTRUCTURA DEL HEADER ==="
echo "--- Archivo local ---"
grep -A 8 "Panel de Administración" dashboard.html | grep -A 5 "header-left" | head -8
echo ""
echo "--- Archivo contenedor ---"
docker exec "$CONTAINER" grep -A 8 "Panel de Administración" "$DASHBOARD_PATH" 2>/dev/null | grep -A 5 "header-left" | head -8
echo ""

# 5. Ver CSS de header-left
echo "=== 4. CSS DE header-left ==="
echo "--- Archivo local ---"
grep -A 5 "\.header-left" dashboard.html | head -6
echo ""
echo "--- Archivo contenedor ---"
docker exec "$CONTAINER" grep -A 5 "\.header-left" "$DASHBOARD_PATH" 2>/dev/null | head -6
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
