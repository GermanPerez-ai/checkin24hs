#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR ESTRUCTURA DEL HEADER"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
DASHBOARD_PATH="/app/dashboard.html"

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Ver estructura HTML del header (buscando donde está el h1 "Panel de Administración")
echo "=== 1. ESTRUCTURA HTML DEL HEADER ==="
docker exec "$CONTAINER" grep -B 5 -A 10 'Panel de Administración' "$DASHBOARD_PATH" 2>/dev/null | grep -A 10 "class=\"header" | head -15
echo ""

# 2. Verificar CSS de .header
echo "=== 2. CSS DE .header ==="
docker exec "$CONTAINER" grep -A 8 "^\s*\.header {" "$DASHBOARD_PATH" 2>/dev/null | head -10
echo ""

# 3. Verificar CSS de .header-left
echo "=== 3. CSS DE .header-left ==="
docker exec "$CONTAINER" grep -A 5 "^\s*\.header-left" "$DASHBOARD_PATH" 2>/dev/null
echo ""

# 4. Verificar si hay estilos inline en el header
echo "=== 4. ESTILOS INLINE EN HEADER ==="
docker exec "$CONTAINER" grep -B 2 -A 5 "class=\"header\"" "$DASHBOARD_PATH" 2>/dev/null | head -10
echo ""

# 5. Buscar si hay h1 directamente en .header (sin header-left)
echo "=== 5. VERIFICAR ESTRUCTURA ==="
echo "Buscando 'h1' dentro del contexto del header..."
docker exec "$CONTAINER" awk '/class="header"/,/<\/div>/ {print}' "$DASHBOARD_PATH" 2>/dev/null | head -20
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
