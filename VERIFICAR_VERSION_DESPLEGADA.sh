#!/bin/bash
# Verificar qué versión del dashboard está desplegada

echo "=========================================="
echo "🔍 Verificando versión del dashboard desplegada"
echo "=========================================="
echo ""

DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

echo "1️⃣ Verificando versión en dashboard.html del contenedor..."
VERSION=$(docker exec "$DASHBOARD_CONTAINER" grep "window.DASHBOARD_VERSION" /app/dashboard.html 2>/dev/null | grep -oP "['\"][^'\"]+['\"]" | head -1 | tr -d "'\"")
BUILD_TIMESTAMP=$(docker exec "$DASHBOARD_CONTAINER" grep "window.BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | grep -oP "['\"][^'\"]+['\"]" | head -1 | tr -d "'\"")

if [ ! -z "$VERSION" ]; then
    echo "✅ Versión encontrada: $VERSION"
else
    echo "⚠️  No se encontró DASHBOARD_VERSION"
fi

if [ ! -z "$BUILD_TIMESTAMP" ]; then
    echo "✅ Build timestamp: $BUILD_TIMESTAMP"
else
    echo "⚠️  No se encontró BUILD_TIMESTAMP"
fi

echo ""
echo "2️⃣ Verificando versión de supabase-client.js en dashboard.html..."
SUPABASE_VERSION=$(docker exec "$DASHBOARD_CONTAINER" grep "supabase-client.js" /app/dashboard.html 2>/dev/null | grep -oP 'v=[0-9.]+' | head -1 | cut -d= -f2)

if [ ! -z "$SUPABASE_VERSION" ]; then
    echo "✅ Versión de supabase-client.js: $SUPABASE_VERSION"
    if [ "$SUPABASE_VERSION" = "3.1.1" ]; then
        echo "   ✅ Versión correcta (3.1.1)"
    else
        echo "   ⚠️  Versión incorrecta (debería ser 3.1.1)"
    fi
else
    echo "⚠️  No se encontró versión de supabase-client.js"
fi

echo ""
echo "3️⃣ Verificando log de verificación temprana..."
VERIFICATION_LOG=$(docker exec "$DASHBOARD_CONTAINER" grep -c "VERIFICACIÓN TEMPRANA DE VERSIÓN DEL CÓDIGO" /app/dashboard.html 2>/dev/null)

if [ "$VERIFICATION_LOG" -gt 0 ]; then
    echo "✅ Log de verificación temprana encontrado (código nuevo)"
else
    echo "❌ Log de verificación temprana NO encontrado (código viejo)"
fi

echo ""
echo "4️⃣ Verificando fecha de modificación del archivo..."
FILE_DATE=$(docker exec "$DASHBOARD_CONTAINER" stat -c %y /app/dashboard.html 2>/dev/null | cut -d' ' -f1)
echo "Fecha de modificación: $FILE_DATE"

echo ""
echo "5️⃣ Verificando si el endpoint /api/version existe en server.js..."
ENDPOINT_EXISTS=$(docker exec "$DASHBOARD_CONTAINER" grep -c "/api/version" /app/server.js 2>/dev/null)

if [ "$ENDPOINT_EXISTS" -gt 0 ]; then
    echo "✅ Endpoint /api/version existe en server.js"
else
    echo "❌ Endpoint /api/version NO existe en server.js"
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
if [ "$SUPABASE_VERSION" != "3.1.1" ] || [ "$VERIFICATION_LOG" -eq 0 ]; then
    echo "❌ El dashboard desplegado es la versión VIEJA"
    echo ""
    echo "Solución:"
    echo "  1. Ve a EasyPanel"
    echo "  2. Ve al servicio dashboard"
    echo "  3. Haz clic en 'Deploy' o 'Redeploy'"
    echo "  4. Espera a que termine el build (2-5 minutos)"
    echo "  5. Verifica que la versión sea 2.1.0 y supabase-client.js?v=3.1.1"
else
    echo "✅ El dashboard desplegado es la versión NUEVA"
    echo ""
    echo "Si el navegador muestra la versión vieja, es caché:"
    echo "  - Presiona Ctrl+Shift+R (hard refresh)"
    echo "  - O abre en modo incógnito"
fi
echo ""
