#!/bin/bash
# Script para verificar qué versión del código está cargada en el servidor

echo "🔍 VERIFICANDO VERSIÓN DEL CÓDIGO EN EL SERVIDOR"
echo "=========================================="
echo ""

# 1. Buscar contenedor del dashboard
echo "1️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep dashboard | grep -v proxy | head -1)
echo "   Nombre: $CONTAINER_NAME"
echo ""

# 2. Buscar dashboard.html en el contenedor
echo "2️⃣ Buscando dashboard.html en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
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
    echo "⚠️ Buscando en todo el contenedor..."
    DASHBOARD_PATH=$(docker exec "$CONTAINER_ID" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
    if [ -n "$DASHBOARD_PATH" ]; then
        echo "✅ Encontrado en: $DASHBOARD_PATH"
    else
        echo "❌ No se encontró dashboard.html en el contenedor"
        exit 1
    fi
fi

echo ""

# 3. Verificar tamaño del archivo
echo "3️⃣ Verificando tamaño del archivo..."
SIZE=$(docker exec "$CONTAINER_ID" stat -c%s "$DASHBOARD_PATH" 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z "$DASHBOARD_PATH" 2>/dev/null)
echo "   Tamaño: $SIZE bytes"
echo ""

# 4. Verificar si tiene el código nuevo
echo "4️⃣ Verificando si tiene el código nuevo..."
echo "   Buscando: 'VERIFICACIÓN TEMPRANA DE VERSIÓN DEL CÓDIGO'..."

if docker exec "$CONTAINER_ID" grep -q "VERIFICACIÓN TEMPRANA DE VERSIÓN DEL CÓDIGO" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "   ✅ CÓDIGO NUEVO ENCONTRADO: Tiene verificación temprana"
    TIENE_NUEVO=true
else
    echo "   ❌ CÓDIGO ANTIGUO: No tiene verificación temprana"
    TIENE_NUEVO=false
fi

echo ""

# 5. Verificar si tiene 'VERSIÓN ACTUALIZADA'
echo "5️⃣ Verificando si tiene 'VERSIÓN ACTUALIZADA' en loadExpensesData..."
if docker exec "$CONTAINER_ID" grep -q "VERSIÓN ACTUALIZADA de loadExpensesData" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "   ✅ Tiene 'VERSIÓN ACTUALIZADA' en loadExpensesData"
else
    echo "   ❌ NO tiene 'VERSIÓN ACTUALIZADA' en loadExpensesData"
fi

echo ""

# 6. Verificar si tiene 'CODIGO_ACTUALIZADO_2026_01_10'
echo "6️⃣ Verificando si tiene variable de verificación..."
if docker exec "$CONTAINER_ID" grep -q "CODIGO_ACTUALIZADO_2026_01_10" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "   ✅ Tiene variable de verificación CODIGO_ACTUALIZADO_2026_01_10"
else
    echo "   ❌ NO tiene variable de verificación CODIGO_ACTUALIZADO_2026_01_10"
fi

echo ""

# 7. Mostrar primeras líneas del archivo para verificar
echo "7️⃣ Mostrando primeras 30 líneas del archivo..."
docker exec "$CONTAINER_ID" head -30 "$DASHBOARD_PATH" 2>/dev/null | grep -E "(DOCTYPE|VERIFICACIÓN|CODIGO_ACTUALIZADO)" || echo "   (No se encontraron líneas relevantes)"
echo ""

# 8. Resumen
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
if [ "$TIENE_NUEVO" = true ]; then
    echo "✅ El código NUEVO está en el contenedor"
    echo "   Si no ves los logs en el navegador, el problema es caché del navegador"
    echo "   Solución: Presiona Ctrl+Shift+R para forzar recarga"
else
    echo "❌ El código ANTIGUO está en el contenedor"
    echo "   La imagen Docker necesita ser reconstruida desde GitHub"
    echo "   El script FORZAR_ACTUALIZACION_DASHBOARD.sh solo reinicia el contenedor"
    echo "   Necesitas reconstruir la imagen Docker desde GitHub"
fi
echo ""
