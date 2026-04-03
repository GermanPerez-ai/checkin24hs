#!/bin/bash
echo "=========================================="
echo "🔍 VERIFICACIÓN DE VERSIÓN DEL DASHBOARD"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Archivo local
echo "=== 1. ARCHIVO LOCAL ==="
if [ -f "dashboard.html" ]; then
    LOCAL_VERSION=$(grep -o "window\.DASHBOARD_VERSION = ['\"][^'\"]*['\"]" dashboard.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    LOCAL_BUILD=$(grep -o "window\.BUILD_TIMESTAMP = ['\"][^'\"]*['\"]" dashboard.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    echo "✅ Archivo encontrado: $(pwd)/dashboard.html"
    echo "   Versión: $LOCAL_VERSION"
    echo "   Build:   $LOCAL_BUILD"
else
    echo "❌ No se encontró dashboard.html local"
    LOCAL_VERSION=""
    LOCAL_BUILD=""
fi
echo ""

# 2. Buscar contenedor
echo "=== 2. CONTENEDOR ==="
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | grep -v nginx | head -1)

if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps --format "{{.Names}}" | grep -i "checkin24hs.*dashboard" | head -1)
fi

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER"
echo ""

# 3. Buscar dashboard.html
echo "=== 3. ARCHIVO EN CONTENEDOR ==="
DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    echo "❌ No se encontró dashboard.html en el contenedor"
    exit 1
fi

echo "✅ Archivo encontrado en: $DASHBOARD_PATH"
echo ""

# 4. Extraer versión (copiar archivo temporalmente y extraer)
echo "=== 4. EXTRAYENDO VERSIÓN ==="
docker exec "$CONTAINER" cat "$DASHBOARD_PATH" > /tmp/dashboard_container.html 2>/dev/null

if [ -f "/tmp/dashboard_container.html" ]; then
    CONTAINER_VERSION=$(grep -o "window\.DASHBOARD_VERSION = ['\"][^'\"]*['\"]" /tmp/dashboard_container.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    CONTAINER_BUILD=$(grep -o "window\.BUILD_TIMESTAMP = ['\"][^'\"]*['\"]" /tmp/dashboard_container.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    rm -f /tmp/dashboard_container.html
    
    echo "   Versión: $CONTAINER_VERSION"
    echo "   Build:   $CONTAINER_BUILD"
else
    echo "⚠️  No se pudo copiar el archivo"
    CONTAINER_VERSION=""
    CONTAINER_BUILD=""
fi
echo ""

# 5. Comparación
echo "=== 5. COMPARACIÓN ==="
if [ -n "$CONTAINER_VERSION" ] && [ -n "$CONTAINER_BUILD" ]; then
    if [ "$LOCAL_VERSION" = "$CONTAINER_VERSION" ] && [ "$LOCAL_BUILD" = "$CONTAINER_BUILD" ]; then
        echo "✅ LOS ARCHIVOS SON IGUALES"
        echo ""
        echo "📋 Valores que debes ver en Chrome:"
        echo "   window.DASHBOARD_VERSION = '$CONTAINER_VERSION'"
        echo "   window.BUILD_TIMESTAMP = '$CONTAINER_BUILD'"
    else
        echo "⚠️  LOS ARCHIVOS SON DIFERENTES"
        echo ""
        echo "Local:"
        echo "   Versión: $LOCAL_VERSION"
        echo "   Build:   $LOCAL_BUILD"
        echo ""
        echo "Contenedor:"
        echo "   Versión: $CONTAINER_VERSION"
        echo "   Build:   $CONTAINER_BUILD"
    fi
else
    echo "⚠️  No se pudo extraer la versión del contenedor"
    echo "   Local - Versión: $LOCAL_VERSION"
    echo "   Local - Build: $LOCAL_BUILD"
fi

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
