#!/bin/bash
# Script para verificar qué versión del dashboard está corriendo

echo "=========================================="
echo "🔍 VERIFICANDO VERSIÓN DEL DASHBOARD"
echo "=========================================="
echo ""

# Buscar contenedor del dashboard
echo "1️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "📋 Contenedores corriendo:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -i dashboard || echo "   Ninguno encontrado"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar rutas posibles del dashboard
echo "2️⃣ Buscando archivo dashboard.html en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
    "/app/deploy/dashboard.html"
    "/app/index.html"
)

DASHBOARD_PATH=""
for path in "${DASHBOARD_PATHS[@]}"; do
    if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
        DASHBOARD_PATH="$path"
        echo "✅ Encontrado en: $path"
        break
    fi
done

if [ -z "$DASHBOARD_PATH" ]; then
    echo "⚠️ No se encontró dashboard.html, listando archivos en /app:"
    docker exec "$CONTAINER_ID" ls -la /app 2>/dev/null | head -20
    exit 1
fi

echo ""

# Verificar función loadHotelsForFlor
echo "3️⃣ Verificando función loadHotelsForFlor..."
if docker exec "$CONTAINER_ID" grep -q "async function loadHotelsForFlor" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Función loadHotelsForFlor encontrada (versión nueva)"
    HAS_FUNCTION=true
else
    echo "❌ Función loadHotelsForFlor NO encontrada (versión antigua)"
    HAS_FUNCTION=false
fi

# Verificar llamada a loadHotelsForFlor en showFlorTab
echo ""
echo "4️⃣ Verificando llamada a loadHotelsForFlor en showFlorTab..."
if docker exec "$CONTAINER_ID" grep -q "loadHotelsForFlor().catch" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Llamada con .catch() encontrada (versión nueva)"
    HAS_CALL=true
else
    echo "❌ Llamada con .catch() NO encontrada (versión antigua)"
    HAS_CALL=false
fi

# Verificar filtro de hoteles activos
echo ""
echo "5️⃣ Verificando filtro de hoteles activos..."
if docker exec "$CONTAINER_ID" grep -q "hotel.active !== false && hotel.activo !== false" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Filtro de hoteles activos encontrado (versión nueva)"
    HAS_FILTER=true
else
    echo "❌ Filtro de hoteles activos NO encontrado (versión antigua)"
    HAS_FILTER=false
fi

# Obtener tamaño del archivo
echo ""
echo "6️⃣ Tamaño del archivo:"
FILE_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s "$DASHBOARD_PATH" 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z "$DASHBOARD_PATH" 2>/dev/null)
echo "   Tamaño: $FILE_SIZE bytes ($(echo "scale=2; $FILE_SIZE/1024/1024" | bc) MB)"

# Obtener fecha de modificación
echo ""
echo "7️⃣ Fecha de modificación:"
docker exec "$CONTAINER_ID" stat "$DASHBOARD_PATH" 2>/dev/null | grep -i modify || docker exec "$CONTAINER_ID" ls -lh "$DASHBOARD_PATH" 2>/dev/null

# Comparar con versión local
echo ""
echo "8️⃣ Comparando con versión local..."
if [ -f "deploy/dashboard.html" ]; then
    LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
    echo "   Tamaño local: $LOCAL_SIZE bytes ($(echo "scale=2; $LOCAL_SIZE/1024/1024" | bc) MB)"
    
    if [ "$FILE_SIZE" -eq "$LOCAL_SIZE" ]; then
        echo "   ✅ Tamaños coinciden"
    else
        echo "   ⚠️ Tamaños NO coinciden (diferencia: $((FILE_SIZE - LOCAL_SIZE)) bytes)"
    fi
    
    # Verificar función en local
    if grep -q "async function loadHotelsForFlor" deploy/dashboard.html 2>/dev/null; then
        echo "   ✅ Función existe en versión local"
    else
        echo "   ❌ Función NO existe en versión local"
    fi
else
    echo "   ⚠️ No se encontró deploy/dashboard.html localmente"
fi

# Resumen
echo ""
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Contenedor: $CONTAINER_ID"
echo "Ruta: $DASHBOARD_PATH"
echo "Tamaño: $FILE_SIZE bytes"
echo ""
echo "Características:"
echo "  - Función loadHotelsForFlor: $([ "$HAS_FUNCTION" = true ] && echo "✅" || echo "❌")"
echo "  - Llamada con .catch(): $([ "$HAS_CALL" = true ] && echo "✅" || echo "❌")"
echo "  - Filtro hoteles activos: $([ "$HAS_FILTER" = true ] && echo "✅" || echo "❌")"
echo ""

if [ "$HAS_FUNCTION" = true ] && [ "$HAS_CALL" = true ] && [ "$HAS_FILTER" = true ]; then
    echo "✅ VERSIÓN CORRECTA (nueva) detectada"
else
    echo "❌ VERSIÓN ANTIGUA detectada - Necesita actualización"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   1. Subir dashboard.html actualizado al servidor"
    echo "   2. Reiniciar el contenedor del dashboard"
    echo "   3. Limpiar caché del navegador (Ctrl+Shift+R)"
fi
echo "=========================================="

