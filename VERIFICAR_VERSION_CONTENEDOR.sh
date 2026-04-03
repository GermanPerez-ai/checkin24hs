#!/bin/bash
# Script rápido para verificar la versión del dashboard en el contenedor

CONTAINER_ID="a8f69fa889fa"
EXPECTED_BUILD=61
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"

echo "=========================================="
echo "🔍 VERIFICACIÓN RÁPIDA DEL DASHBOARD"
echo "=========================================="
echo ""

# Verificar versión en contenedor
echo "1️⃣ Verificando versión en el contenedor..."
CONTAINER_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1)

if [ -z "$CONTAINER_BUILD" ]; then
    echo "❌ No se pudo obtener BUILD_NUMBER del contenedor"
    echo "   Intentando otras rutas..."
    
    # Intentar otras rutas
    for path in "/app/dashboard.html" "/usr/share/nginx/html/dashboard.html" "/var/www/html/dashboard.html"; do
        if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
            CONTAINER_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$path" 2>/dev/null | head -1)
            if [ -n "$CONTAINER_BUILD" ]; then
                echo "✅ Encontrado en: $path"
                break
            fi
        fi
    done
fi

if [ -z "$CONTAINER_BUILD" ]; then
    echo "❌ No se pudo obtener BUILD_NUMBER"
    exit 1
fi

echo "   Build en contenedor: #$CONTAINER_BUILD"
echo ""

# Verificar versión en GitHub
echo "2️⃣ Verificando versión en GitHub..."
GITHUB_BUILD=$(curl -s -L "$GITHUB_REPO" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)

if [ -n "$GITHUB_BUILD" ]; then
    echo "   Build en GitHub: #$GITHUB_BUILD"
else
    echo "   ⚠️ No se pudo obtener BUILD_NUMBER de GitHub"
    GITHUB_BUILD="unknown"
fi

echo ""

# Comparar
echo "=========================================="
echo "📊 COMPARACIÓN"
echo "=========================================="
echo "Versión esperada: Build #$EXPECTED_BUILD"
echo "Versión en contenedor: Build #$CONTAINER_BUILD"
echo "Versión en GitHub: Build #$GITHUB_BUILD"
echo ""

if [ "$CONTAINER_BUILD" = "$EXPECTED_BUILD" ] || [ "$CONTAINER_BUILD" = "$GITHUB_BUILD" ]; then
    echo "✅ TODO ESTÁ CORRECTO"
    echo "   El contenedor tiene la versión correcta"
else
    echo "⚠️ NECESITA ACTUALIZACIÓN"
    echo "   El contenedor tiene Build #$CONTAINER_BUILD"
    echo "   Se espera Build #$EXPECTED_BUILD (o #$GITHUB_BUILD desde GitHub)"
    echo ""
    echo "📋 Para actualizar, ejecuta:"
    echo "   bash REVISAR_Y_ACTUALIZAR_DASHBOARD.sh"
    echo "   Y selecciona la opción 1 (actualización rápida desde GitHub)"
fi
