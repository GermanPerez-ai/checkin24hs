#!/bin/bash
# Script para verificar qué archivo dashboard.html tiene la imagen

echo "=========================================="
echo "🔍 Verificando Archivo en Imagen Docker"
echo "=========================================="
echo ""

IMAGE_NAME="easypanel/checkin24hs/dashboard:latest"

# Crear contenedor temporal y verificar
echo "1️⃣ Creando contenedor temporal desde la imagen..."
TEMP_CONTAINER=$(docker create "$IMAGE_NAME" 2>/dev/null)

if [ -z "$TEMP_CONTAINER" ]; then
    echo "❌ No se pudo crear contenedor temporal"
    exit 1
fi

echo "   Contenedor temporal: $TEMP_CONTAINER"
echo ""

# Copiar archivo del contenedor
echo "2️⃣ Extrayendo dashboard.html del contenedor..."
TEMP_DIR="/tmp/dashboard_check_$$"
mkdir -p "$TEMP_DIR"
docker cp "$TEMP_CONTAINER:/app/dashboard.html" "$TEMP_DIR/dashboard_from_image.html" 2>/dev/null

if [ ! -f "$TEMP_DIR/dashboard_from_image.html" ]; then
    echo "❌ No se pudo extraer dashboard.html del contenedor"
    docker rm "$TEMP_CONTAINER" 2>/dev/null
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verificar archivo
FILE_SIZE=$(stat -c%s "$TEMP_DIR/dashboard_from_image.html" 2>/dev/null || stat -f%z "$TEMP_DIR/dashboard_from_image.html" 2>/dev/null)
BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" "$TEMP_DIR/dashboard_from_image.html" | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"" || echo "NO")
SUPABASE_VERSION=$(grep -oP "supabase-client\.js\?v=([0-9.]+)" "$TEMP_DIR/dashboard_from_image.html" | head -1 | grep -oP "v=([0-9.]+)" | cut -d= -f2 || echo "NO")
MATERIAL_ICONS=$(grep -c "material-icons.*policy" "$TEMP_DIR/dashboard_from_image.html" 2>/dev/null || echo "0")

echo "   Tamaño del archivo: $FILE_SIZE bytes"
echo "   BUILD_TIMESTAMP: $BUILD_TS"
echo "   supabase-client.js versión: $SUPABASE_VERSION"
echo "   Material Icons (policy): $MATERIAL_ICONS encontrados"
echo ""

# Comparar con GitHub
echo "3️⃣ Comparando con GitHub..."
curl -L -s "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o "$TEMP_DIR/dashboard_from_github.html" 2>/dev/null

if [ -f "$TEMP_DIR/dashboard_from_github.html" ]; then
    GITHUB_SIZE=$(stat -c%s "$TEMP_DIR/dashboard_from_github.html" 2>/dev/null || stat -f%z "$TEMP_DIR/dashboard_from_github.html" 2>/dev/null)
    GITHUB_BUILD=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" "$TEMP_DIR/dashboard_from_github.html" | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    
    echo "   GitHub: $GITHUB_SIZE bytes, BUILD: $GITHUB_BUILD"
    echo "   Imagen: $FILE_SIZE bytes, BUILD: $BUILD_TS"
    echo ""
    
    if [ "$FILE_SIZE" = "$GITHUB_SIZE" ] && [ "$BUILD_TS" = "$GITHUB_BUILD" ]; then
        echo "   ✅ El archivo en la imagen coincide con GitHub"
    else
        echo "   ❌ El archivo en la imagen NO coincide con GitHub"
        if [ "$FILE_SIZE" != "$GITHUB_SIZE" ]; then
            echo "      Tamaño diferente: imagen=$FILE_SIZE, GitHub=$GITHUB_SIZE"
        fi
        if [ "$BUILD_TS" != "$GITHUB_BUILD" ]; then
            echo "      BUILD_TIMESTAMP diferente: imagen=$BUILD_TS, GitHub=$GITHUB_BUILD"
        fi
    fi
fi

# Comparar con archivo local
echo ""
echo "4️⃣ Comparando con archivo local..."
if [ -f "/root/checkin24hs/dashboard.html" ]; then
    LOCAL_SIZE=$(stat -c%s /root/checkin24hs/dashboard.html 2>/dev/null || stat -f%z /root/checkin24hs/dashboard.html 2>/dev/null)
    LOCAL_BUILD=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" /root/checkin24hs/dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    
    echo "   Local: $LOCAL_SIZE bytes, BUILD: $LOCAL_BUILD"
    echo ""
    
    if [ "$FILE_SIZE" = "$LOCAL_SIZE" ] && [ "$BUILD_TS" = "$LOCAL_BUILD" ]; then
        echo "   ✅ El archivo en la imagen coincide con el local"
    else
        echo "   ❌ El archivo en la imagen NO coincide con el local"
        echo "      Esto significa que el Dockerfile copió un archivo diferente"
    fi
fi

# Limpiar
docker rm "$TEMP_CONTAINER" 2>/dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "📋 DIAGNÓSTICO"
echo "=========================================="
echo ""

if [ "$BUILD_TS" = "NO" ]; then
    echo "❌ PROBLEMA: La imagen NO tiene BUILD_TIMESTAMP"
    echo ""
    echo "   Esto significa que el archivo dashboard.html copiado durante el build"
    echo "   es una versión antigua (anterior a cuando se agregó BUILD_TIMESTAMP)"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Verifica que /root/checkin24hs/dashboard.html tenga BUILD_TIMESTAMP"
    echo "   2. Si no lo tiene, descárgalo desde GitHub:"
    echo "      cd /root/checkin24hs"
    echo "      curl -L https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html -o dashboard.html"
    echo "   3. Reconstruye la imagen de nuevo"
elif [ "$FILE_SIZE" != "$GITHUB_SIZE" ]; then
    echo "⚠️ PROBLEMA: El tamaño del archivo no coincide"
    echo ""
    echo "   Imagen: $FILE_SIZE bytes"
    echo "   GitHub: $GITHUB_SIZE bytes"
    echo ""
    echo "   SOLUCIÓN: Actualiza el archivo local y reconstruye"
else
    echo "✅ El archivo en la imagen parece correcto"
fi

echo ""
