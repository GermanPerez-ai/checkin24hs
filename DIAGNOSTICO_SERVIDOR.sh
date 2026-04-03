#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNÓSTICO DEL SERVIDOR"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar contenedor
echo "=== 1. CONTENEDOR ==="
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi
echo "✅ Contenedor: $CONTAINER"
echo ""

# 2. Verificar archivo en el servidor (fuera del contenedor)
echo "=== 2. ARCHIVO EN EL SERVIDOR (fuera del contenedor) ==="
if [ -f "dashboard.html" ]; then
    echo "✅ Archivo encontrado: $(pwd)/dashboard.html"
    echo "   Tamaño: $(du -h dashboard.html | cut -f1)"
    echo "   Encoding: $(file -bi dashboard.html)"
    echo ""
    echo "   Verificando header (primeras 30 líneas después de '<div class=\"header\">'):"
    grep -A 10 'class="header"' dashboard.html | head -15
    echo ""
else
    echo "❌ No se encontró dashboard.html en el servidor"
fi
echo ""

# 3. Verificar archivo dentro del contenedor
echo "=== 3. ARCHIVO DENTRO DEL CONTENEDOR ==="
DASHBOARD_PATH=$(docker exec "$CONTAINER" find /app -name "dashboard.html" -type f 2>/dev/null | head -1)
if [ -z "$DASHBOARD_PATH" ]; then
    echo "❌ No se encontró dashboard.html en el contenedor"
else
    echo "✅ Archivo encontrado: $DASHBOARD_PATH"
    echo "   Tamaño: $(docker exec "$CONTAINER" du -h "$DASHBOARD_PATH" 2>/dev/null | cut -f1)"
    echo "   Encoding: $(docker exec "$CONTAINER" file -bi "$DASHBOARD_PATH" 2>/dev/null)"
    echo ""
    echo "   Verificando header (primeras 15 líneas después de '<div class=\"header\">'):"
    docker exec "$CONTAINER" grep -A 10 'class="header"' "$DASHBOARD_PATH" 2>/dev/null | head -15
    echo ""
fi
echo ""

# 4. Comparar hashes (verificar si se corrompe al copiar)
echo "=== 4. COMPARAR HASHES (verificar corrupción) ==="
if [ -f "dashboard.html" ] && [ -n "$DASHBOARD_PATH" ]; then
    SERVER_HASH=$(md5sum dashboard.html | cut -d' ' -f1)
    CONTAINER_HASH=$(docker exec "$CONTAINER" md5sum "$DASHBOARD_PATH" 2>/dev/null | cut -d' ' -f1)
    echo "   Hash del servidor: $SERVER_HASH"
    echo "   Hash del contenedor: $CONTAINER_HASH"
    if [ "$SERVER_HASH" = "$CONTAINER_HASH" ]; then
        echo "   ✅ Los archivos son idénticos (no hay corrupción)"
    else
        echo "   ⚠️  Los archivos son DIFERENTES (puede haber corrupción o son versiones distintas)"
    fi
fi
echo ""

# 5. Verificar si hay proxy/nginx delante
echo "=== 5. VERIFICAR PROXY/NGINX ==="
if docker ps --format "{{.Names}}" | grep -q nginx; then
    NGINX_CONTAINER=$(docker ps --format "{{.Names}}" | grep nginx | head -1)
    echo "⚠️  Se encontró contenedor nginx: $NGINX_CONTAINER"
    echo "   Esto puede estar modificando el contenido"
else
    echo "✅ No se encontró contenedor nginx"
fi

if docker ps --format "{{.Names}}" | grep -q traefik; then
    TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep traefik | head -1)
    echo "⚠️  Se encontró contenedor traefik: $TRAEFIK_CONTAINER"
    echo "   Esto puede estar modificando el contenido"
else
    echo "✅ No se encontró contenedor traefik"
fi
echo ""

# 6. Verificar serve-dashboard.js
echo "=== 6. VERIFICAR serve-dashboard.js ==="
if docker exec "$CONTAINER" test -f /app/serve-dashboard.js 2>/dev/null; then
    echo "✅ serve-dashboard.js existe en el contenedor"
    echo "   Verificando si tiene Content-Type UTF-8:"
    docker exec "$CONTAINER" grep -n "Content-Type" /app/serve-dashboard.js 2>/dev/null | head -5
    if docker exec "$CONTAINER" grep -q "charset=utf-8" /app/serve-dashboard.js 2>/dev/null; then
        echo "   ✅ Tiene charset=utf-8 configurado"
    else
        echo "   ⚠️  NO tiene charset=utf-8 configurado (necesita actualización)"
    fi
else
    echo "❌ serve-dashboard.js no existe en el contenedor"
fi
echo ""

# 7. Verificar estructura del header en el archivo del contenedor
echo "=== 7. ESTRUCTURA DEL HEADER EN EL CONTENEDOR ==="
if [ -n "$DASHBOARD_PATH" ]; then
    echo "   Buscando 'header-left':"
    docker exec "$CONTAINER" grep -n "header-left" "$DASHBOARD_PATH" 2>/dev/null | head -3
    echo ""
    echo "   Buscando 'Panel de Administración':"
    docker exec "$CONTAINER" grep -n "Panel de" "$DASHBOARD_PATH" 2>/dev/null | head -3
fi
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
