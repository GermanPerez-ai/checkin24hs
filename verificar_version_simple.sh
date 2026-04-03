#!/bin/bash
echo "=== VERIFICACIÓN DE VERSIÓN ==="
cd /root/checkin24hs

# Archivo local
if [ -f "dashboard.html" ]; then
    LOCAL_VERSION=$(grep -o "window\.DASHBOARD_VERSION = ['\"][^'\"]*['\"]" dashboard.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    LOCAL_BUILD=$(grep -o "window\.BUILD_TIMESTAMP = ['\"][^'\"]*['\"]" dashboard.html 2>/dev/null | sed "s/.*['\"]\([^'\"]*\)['\"].*/\1/" | head -1)
    echo "Local - Versión: $LOCAL_VERSION"
    echo "Local - Build: $LOCAL_BUILD"
fi

# Contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | grep -v nginx | head -1)
if [ -n "$CONTAINER" ]; then
    DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
    if [ -n "$DASHBOARD_PATH" ]; then
        CONTAINER_VERSION_LINE=$(docker exec "$CONTAINER" grep "window\.DASHBOARD_VERSION" "$DASHBOARD_PATH" 2>/dev/null | head -1)
        CONTAINER_BUILD_LINE=$(docker exec "$CONTAINER" grep "window\.BUILD_TIMESTAMP" "$DASHBOARD_PATH" 2>/dev/null | head -1)
        CONTAINER_VERSION=$(echo "$CONTAINER_VERSION_LINE" | sed -n "s/.*window\.DASHBOARD_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" | head -1)
        CONTAINER_BUILD=$(echo "$CONTAINER_BUILD_LINE" | sed -n "s/.*window\.BUILD_TIMESTAMP[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" | head -1)
        echo "Contenedor - Versión: $CONTAINER_VERSION"
        echo "Contenedor - Build: $CONTAINER_BUILD"
    fi
fi
