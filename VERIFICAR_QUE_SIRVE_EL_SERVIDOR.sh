#!/bin/bash
# Script para verificar qué versión está sirviendo realmente el servidor

echo "=========================================="
echo "🔍 Verificando qué versión sirve el servidor"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar archivo en /app/dashboard.html
echo "1️⃣ Verificando /app/dashboard.html..."
if docker exec "$CONTAINER_ID" test -f /app/dashboard.html 2>/dev/null; then
    SIZE1=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
    BUILD1=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"")
    echo "   ✅ Existe: $SIZE1 bytes"
    if [ ! -z "$BUILD1" ]; then
        echo "   ✅ BUILD_TIMESTAMP: $BUILD1"
    else
        echo "   ❌ No tiene BUILD_TIMESTAMP"
    fi
else
    echo "   ❌ NO existe"
fi

echo ""

# 2. Verificar si hay otros archivos dashboard.html
echo "2️⃣ Buscando otros archivos dashboard.html en el contenedor..."
OTHER_FILES=$(docker exec "$CONTAINER_ID" find /app -name "dashboard.html" -type f 2>/dev/null)
if [ ! -z "$OTHER_FILES" ]; then
    echo "   Archivos encontrados:"
    echo "$OTHER_FILES" | while read file; do
        SIZE=$(docker exec "$CONTAINER_ID" stat -c%s "$file" 2>/dev/null || echo "unknown")
        echo "   - $file ($SIZE bytes)"
    done
else
    echo "   ✅ Solo hay un archivo dashboard.html"
fi

echo ""

# 3. Verificar qué archivo está leyendo server.js
echo "3️⃣ Verificando server.js para ver qué archivo sirve..."
SERVER_JS=$(docker exec "$CONTAINER_ID" cat /app/server.js 2>/dev/null | grep -E "(dashboard\.html|sendFile|readFile)" | head -5)
if [ ! -z "$SERVER_JS" ]; then
    echo "   Líneas relevantes en server.js:"
    echo "$SERVER_JS" | sed 's/^/   /'
else
    echo "   ⚠️ No se encontraron referencias a dashboard.html en server.js"
fi

echo ""

# 4. Hacer una petición HTTP real al servidor
echo "4️⃣ Haciendo petición HTTP al servidor..."
HTTP_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        // Buscar BUILD_TIMESTAMP en la respuesta
        const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
        const versionMatch = data.match(/window\.DASHBOARD_VERSION\s*=\s*['\"]([^'\"]+)['\"]/);
        const supabaseMatch = data.match(/supabase-client\.js\?v=([0-9.]+)/);
        
        console.log('Status:', res.statusCode);
        console.log('Content-Length:', data.length);
        if (buildMatch) {
            console.log('BUILD_TIMESTAMP en respuesta:', buildMatch[1]);
        } else {
            console.log('BUILD_TIMESTAMP: NO encontrado');
        }
        if (versionMatch) {
            console.log('DASHBOARD_VERSION en respuesta:', versionMatch[1]);
        } else {
            console.log('DASHBOARD_VERSION: NO encontrado');
        }
        if (supabaseMatch) {
            console.log('supabase-client.js versión:', supabaseMatch[1]);
        } else {
            console.log('supabase-client.js: NO encontrado');
        }
        process.exit(0);
    });
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1)

echo "$HTTP_RESPONSE" | while read line; do
    echo "   $line"
done

echo ""

# 5. Verificar si hay caché en el servidor
echo "5️⃣ Verificando si hay archivos de caché..."
CACHE_FILES=$(docker exec "$CONTAINER_ID" find /app -name "*.cache" -o -name "*cache*" -type f 2>/dev/null | head -5)
if [ ! -z "$CACHE_FILES" ]; then
    echo "   Archivos de caché encontrados:"
    echo "$CACHE_FILES" | sed 's/^/   - /'
else
    echo "   ✅ No se encontraron archivos de caché"
fi

echo ""

# 6. Verificar el working directory
echo "6️⃣ Verificando directorio de trabajo..."
WORK_DIR=$(docker exec "$CONTAINER_ID" pwd 2>/dev/null)
echo "   Working directory: $WORK_DIR"

# Verificar archivos en el directorio de trabajo
echo "   Archivos en $WORK_DIR:"
docker exec "$CONTAINER_ID" ls -lah "$WORK_DIR" 2>/dev/null | grep -E "(dashboard|server)" | head -10 | sed 's/^/   /'

echo ""

# 7. Verificar si Express está usando un directorio estático diferente
echo "7️⃣ Verificando configuración de Express..."
EXPRESS_CONFIG=$(docker exec "$CONTAINER_ID" grep -E "(express\.static|__dirname|path\.join)" /app/server.js 2>/dev/null | head -5)
if [ ! -z "$EXPRESS_CONFIG" ]; then
    echo "   Configuración de Express:"
    echo "$EXPRESS_CONFIG" | sed 's/^/   /'
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

# Analizar la respuesta HTTP
if echo "$HTTP_RESPONSE" | grep -q "BUILD_TIMESTAMP en respuesta"; then
    BUILD_HTTP=$(echo "$HTTP_RESPONSE" | grep "BUILD_TIMESTAMP en respuesta" | cut -d: -f2 | tr -d ' ')
    echo "✅ El servidor SÍ está sirviendo BUILD_TIMESTAMP: $BUILD_HTTP"
    echo ""
    echo "   Si el navegador muestra versión antigua, es problema de CACHÉ del navegador"
    echo ""
    echo "   Solución:"
    echo "   1. Abre ventana de incógnito (Ctrl+Shift+N)"
    echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
    echo "   3. O limpia la caché del navegador completamente"
else
    echo "❌ El servidor NO está sirviendo BUILD_TIMESTAMP"
    echo ""
    echo "   Esto significa que está sirviendo una versión antigua"
    echo ""
    echo "   Posibles causas:"
    echo "   1. El servidor está leyendo de otra ruta"
    echo "   2. Hay un archivo dashboard.html en otra ubicación"
    echo "   3. Express está usando caché"
    echo ""
    echo "   Solución: Reiniciar el servicio"
    echo "   docker service update --force checkin24hs_dashboard"
fi

echo ""
