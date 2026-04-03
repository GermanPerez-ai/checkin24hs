#!/bin/bash
# Script para verificar si el dashboard.html en el servidor tiene los cambios

echo "=========================================="
echo "VERIFICANDO CAMBIOS EN EL SERVIDOR"
echo "=========================================="
echo ""

# 1. Verificar archivo local
echo "1. Verificando archivo local deploy/dashboard.html..."
if grep -q "🔍 Verificando tab:" deploy/dashboard.html 2>/dev/null; then
    echo "✅ Archivo local tiene los cambios de depuración"
else
    echo "❌ Archivo local NO tiene los cambios de depuración"
fi

if grep -q "Cargando hoteles para selector (knowledge/policies)" deploy/dashboard.html 2>/dev/null; then
    echo "✅ Archivo local tiene la función loadHotelsForFlor"
else
    echo "❌ Archivo local NO tiene la función loadHotelsForFlor"
fi

echo ""

# 2. Buscar contenedor
echo "2. Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps --filter name=dashboard --format '{{.ID}}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 3. Verificar archivo en el contenedor
echo "3. Verificando archivo en el contenedor..."
DASHBOARD_PATH="/app/dashboard.html"

if docker exec "$CONTAINER_ID" grep -q "🔍 Verificando tab:" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene los cambios de depuración"
    HAS_DEBUG=true
else
    echo "❌ Contenedor NO tiene los cambios de depuración"
    HAS_DEBUG=false
fi

if docker exec "$CONTAINER_ID" grep -q "Cargando hoteles para selector (knowledge/policies)" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene la función loadHotelsForFlor"
    HAS_FUNCTION=true
else
    echo "❌ Contenedor NO tiene la función loadHotelsForFlor"
    HAS_FUNCTION=false
fi

echo ""

# 4. Mostrar resumen
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

if [ "$HAS_DEBUG" = true ] && [ "$HAS_FUNCTION" = true ]; then
    echo "✅ El contenedor tiene TODOS los cambios"
    echo ""
    echo "Si no ves la información, el problema puede ser:"
    echo "  1. Caché del navegador (limpia con Ctrl+Shift+R)"
    echo "  2. La función no se está ejecutando (revisa la consola)"
    echo "  3. El selector no existe en el DOM cuando se ejecuta"
else
    echo "❌ El contenedor NO tiene todos los cambios"
    echo ""
    echo "Necesitas actualizar el archivo:"
    echo "  1. Sube deploy/dashboard.html al servidor"
    echo "  2. Ejecuta el script de actualización"
fi

echo "=========================================="



