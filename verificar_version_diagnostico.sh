#!/bin/bash
echo "=== DIAGNÓSTICO DE VERSIÓN ==="
cd /root/checkin24hs

# 1. Archivo local
echo "1. ARCHIVO LOCAL:"
if [ -f "dashboard.html" ]; then
    LOCAL_VERSION=$(grep -o "window\.DASHBOARD_VERSION = ['\"][^'\"]*['\"]" dashboard.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    LOCAL_BUILD=$(grep -o "window\.BUILD_TIMESTAMP = ['\"][^'\"]*['\"]" dashboard.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    echo "   Versión: $LOCAL_VERSION"
    echo "   Build: $LOCAL_BUILD"
fi
echo ""

# 2. Buscar contenedor
echo "2. BUSCANDO CONTENEDOR:"
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | grep -v nginx | head -1)
if [ -z "$CONTAINER" ]; then
    echo "   No encontrado con 'name=dashboard', buscando todos..."
    docker ps --format "  {{.Names}}" | head -5
    CONTAINER=$(docker ps --format "{{.Names}}" | grep -i "checkin24hs.*dashboard" | head -1)
fi
if [ -n "$CONTAINER" ]; then
    echo "   ✅ Contenedor: $CONTAINER"
else
    echo "   ❌ No se encontró contenedor"
fi
echo ""

# 3. Buscar dashboard.html
if [ -n "$CONTAINER" ]; then
    echo "3. BUSCANDO dashboard.html:"
    DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
    if [ -n "$DASHBOARD_PATH" ]; then
        echo "   ✅ Encontrado en: $DASHBOARD_PATH"
        echo ""
        echo "4. EXTRAYENDO VERSIÓN:"
        VERSION_LINE=$(docker exec "$CONTAINER" grep "window\.DASHBOARD_VERSION" "$DASHBOARD_PATH" 2>/dev/null | head -1)
        BUILD_LINE=$(docker exec "$CONTAINER" grep "window\.BUILD_TIMESTAMP" "$DASHBOARD_PATH" 2>/dev/null | head -1)
        echo "   Línea VERSION: $VERSION_LINE"
        echo "   Línea BUILD: $BUILD_LINE"
    else
        echo "   ❌ No se encontró dashboard.html"
    fi
fi
