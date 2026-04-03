#!/bin/bash
echo "=========================================="
echo "VERIFICANDO ACTUALIZACIÓN DEL DASHBOARD"
echo "=========================================="
echo ""

# Verificar archivo local
echo "1. Verificando archivo local (deploy/dashboard.html)..."
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ ERROR: No se encontró deploy/dashboard.html"
    exit 1
fi

echo "✅ Archivo local existe"

# Verificar que tiene los cambios necesarios
if grep -q "normalizeServerUrl" deploy/dashboard.html && grep -q "URL normalizada" deploy/dashboard.html; then
    echo "✅ Archivo local tiene la función normalizeServerUrl"
else
    echo "❌ Archivo local NO tiene la función normalizeServerUrl"
    echo "   Necesitas actualizar el archivo desde tu máquina local"
    exit 1
fi

if grep -q "tryConnect.*normalizeServerUrl" deploy/dashboard.html; then
    echo "✅ Archivo local tiene normalización en tryConnect"
else
    echo "⚠️  Archivo local NO tiene normalización en tryConnect"
fi

echo ""
echo "2. Verificando contenedor del dashboard..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ ERROR: No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"

# Buscar ruta del dashboard en el contenedor
DASHBOARD_PATH="/app/dashboard.html"
if ! docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" 2>/dev/null; then
    DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
    if ! docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" 2>/dev/null; then
        DASHBOARD_PATH="/var/www/html/dashboard.html"
    fi
fi

echo "✅ Ruta del dashboard en contenedor: $DASHBOARD_PATH"

echo ""
echo "3. Verificando archivo en el contenedor..."
if docker exec $CONTAINER_ID grep -q "normalizeServerUrl" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene la función normalizeServerUrl"
    HAS_NORMALIZE=true
else
    echo "❌ Contenedor NO tiene la función normalizeServerUrl"
    HAS_NORMALIZE=false
fi

if docker exec $CONTAINER_ID grep -q "URL normalizada" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene los logs de normalización"
    HAS_LOGS=true
else
    echo "❌ Contenedor NO tiene los logs de normalización"
    HAS_LOGS=false
fi

if docker exec $CONTAINER_ID grep -q "tryConnect.*normalizeServerUrl" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene normalización en tryConnect"
    HAS_TRYCONNECT=true
else
    echo "❌ Contenedor NO tiene normalización en tryConnect"
    HAS_TRYCONNECT=false
fi

echo ""
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

if [ "$HAS_NORMALIZE" = true ] && [ "$HAS_LOGS" = true ] && [ "$HAS_TRYCONNECT" = true ]; then
    echo "✅ El contenedor tiene TODOS los cambios necesarios"
    echo ""
    echo "Si aún ves errores, el problema puede ser:"
    echo "  1. Caché del navegador (limpia con Ctrl+Shift+R)"
    echo "  2. La URL en localStorage sigue sin protocolo"
    echo "     Solución: Borra la URL y vuelve a guardarla"
else
    echo "❌ El contenedor NO tiene todos los cambios"
    echo ""
    echo "Necesitas actualizar el archivo:"
    echo "  1. Asegúrate de que deploy/dashboard.html esté actualizado"
    echo "  2. Ejecuta: bash ACTUALIZAR_DASHBOARD_SERVIDOR.sh"
fi

echo "=========================================="



