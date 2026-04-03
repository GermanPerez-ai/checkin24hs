#!/bin/bash
# Script para verificar el contenido real del dashboard.html en el contenedor

echo "=========================================="
echo "🔍 Verificando Contenido del Dashboard en Contenedor"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar que el archivo existe
echo "1️⃣ Verificando que el archivo existe..."
if docker exec "$CONTAINER_ID" test -f /app/dashboard.html 2>/dev/null; then
    echo "✅ Archivo existe"
else
    echo "❌ Archivo NO existe"
    exit 1
fi

echo ""

# 2. Ver primeras líneas del archivo
echo "2️⃣ Primeras 15 líneas del archivo:"
docker exec "$CONTAINER_ID" head -15 /app/dashboard.html 2>/dev/null | cat -A
echo ""

# 3. Buscar BUILD_TIMESTAMP con múltiples métodos
echo "3️⃣ Buscando BUILD_TIMESTAMP (múltiples métodos)..."
echo ""

# Método 1: grep simple
BUILD_LINE1=$(docker exec "$CONTAINER_ID" grep -i "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1)
if [ ! -z "$BUILD_LINE1" ]; then
    echo "✅ Método 1 (grep simple):"
    echo "   $BUILD_LINE1"
else
    echo "❌ Método 1: No encontrado"
fi

# Método 2: grep con contexto
BUILD_LINE2=$(docker exec "$CONTAINER_ID" grep -A 2 -B 2 "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -5)
if [ ! -z "$BUILD_LINE2" ]; then
    echo "✅ Método 2 (con contexto):"
    echo "$BUILD_LINE2" | sed 's/^/   /'
else
    echo "❌ Método 2: No encontrado"
fi

# Método 3: Buscar cualquier línea con "window.BUILD"
BUILD_LINE3=$(docker exec "$CONTAINER_ID" grep "window.BUILD" /app/dashboard.html 2>/dev/null | head -3)
if [ ! -z "$BUILD_LINE3" ]; then
    echo "✅ Método 3 (window.BUILD):"
    echo "$BUILD_LINE3" | sed 's/^/   /'
else
    echo "❌ Método 3: No encontrado"
fi

echo ""

# 4. Buscar DASHBOARD_VERSION
echo "4️⃣ Buscando DASHBOARD_VERSION..."
VERSION_LINE=$(docker exec "$CONTAINER_ID" grep -i "DASHBOARD_VERSION" /app/dashboard.html 2>/dev/null | head -3)
if [ ! -z "$VERSION_LINE" ]; then
    echo "✅ Encontrado:"
    echo "$VERSION_LINE" | sed 's/^/   /'
else
    echo "❌ No encontrado"
fi

echo ""

# 5. Verificar codificación del archivo
echo "5️⃣ Verificando codificación del archivo..."
FILE_ENCODING=$(docker exec "$CONTAINER_ID" file -bi /app/dashboard.html 2>/dev/null || echo "unknown")
echo "   Codificación: $FILE_ENCODING"

# Verificar si tiene caracteres especiales correctos
if docker exec "$CONTAINER_ID" grep -q "VERSIÓN:" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ Tiene 'VERSIÓN' con tilde"
elif docker exec "$CONTAINER_ID" grep -q "VERSI?N:" /app/dashboard.html 2>/dev/null; then
    echo "   ❌ Tiene 'VERSI?N' (problema UTF-8)"
else
    echo "   ⚠️ No se pudo verificar"
fi

echo ""

# 6. Comparar tamaño con el archivo descargado
echo "6️⃣ Comparando tamaños..."
CONTAINER_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño en contenedor: $CONTAINER_SIZE bytes"

# Descargar temporalmente para comparar
TEMP_FILE="/tmp/dashboard_compare_$$.html"
curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o "$TEMP_FILE" 2>/dev/null
if [ -f "$TEMP_FILE" ]; then
    GITHUB_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || stat -f%z "$TEMP_FILE" 2>/dev/null)
    echo "   Tamaño en GitHub: $GITHUB_SIZE bytes"
    
    if [ "$CONTAINER_SIZE" = "$GITHUB_SIZE" ]; then
        echo "   ✅ Los tamaños coinciden"
    else
        DIFF=$((CONTAINER_SIZE - GITHUB_SIZE))
        echo "   ⚠️ Diferencia: $DIFF bytes"
    fi
    
    rm -f "$TEMP_FILE"
fi

echo ""

# 7. Intentar leer directamente las líneas específicas
echo "7️⃣ Leyendo líneas específicas (10-15)..."
docker exec "$CONTAINER_ID" sed -n '10,15p' /app/dashboard.html 2>/dev/null | cat -A
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO"
echo "=========================================="
echo ""

# Verificar si el problema es de codificación o de contenido
if [ ! -z "$BUILD_LINE1" ] || [ ! -z "$BUILD_LINE2" ] || [ ! -z "$BUILD_LINE3" ]; then
    echo "✅ El archivo SÍ tiene BUILD_TIMESTAMP"
    echo "   El problema puede ser con el método de extracción"
    echo ""
    echo "   Prueba verificar manualmente:"
    echo "   docker exec $CONTAINER_ID grep 'BUILD_TIMESTAMP' /app/dashboard.html | head -1"
else
    echo "❌ El archivo NO tiene BUILD_TIMESTAMP"
    echo "   Esto significa que el archivo copiado no es el correcto"
    echo ""
    echo "   Posibles causas:"
    echo "   1. El archivo se corrompió durante la copia"
    echo "   2. Hay un problema de codificación"
    echo "   3. El archivo en GitHub no tiene BUILD_TIMESTAMP"
    echo ""
    echo "   Solución: Intentar copiar de nuevo o verificar el archivo en GitHub"
fi

echo ""
