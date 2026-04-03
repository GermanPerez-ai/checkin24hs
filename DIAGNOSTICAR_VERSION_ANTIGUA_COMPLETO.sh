#!/bin/bash
# Script completo para diagnosticar por qué se sirve la versión antigua

echo "=========================================="
echo "🔍 Diagnóstico Completo - Versión Antigua"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar archivo en el contenedor
echo "1️⃣ Verificando archivo en /app/dashboard.html..."
FILE_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
FILE_DATE=$(docker exec "$CONTAINER_ID" stat -c %y /app/dashboard.html 2>/dev/null | cut -d' ' -f1 || echo "")
echo "   Tamaño: $FILE_SIZE bytes"
echo "   Fecha: $FILE_DATE"

BUILD_TS_FILE=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"")
if [ ! -z "$BUILD_TS_FILE" ]; then
    echo "   ✅ BUILD_TIMESTAMP en archivo: $BUILD_TS_FILE"
else
    echo "   ❌ BUILD_TIMESTAMP NO encontrado en archivo"
fi

# Verificar supabase-client.js versión en el archivo
SUPABASE_VERSION=$(docker exec "$CONTAINER_ID" grep -oP "supabase-client\.js\?v=([0-9.]+)" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "v=([0-9.]+)" | cut -d= -f2)
if [ ! -z "$SUPABASE_VERSION" ]; then
    echo "   supabase-client.js versión en archivo: $SUPABASE_VERSION"
else
    echo "   ⚠️ No se encontró versión de supabase-client.js en archivo"
fi

echo ""

# 2. Verificar qué está sirviendo realmente el servidor
echo "2️⃣ Verificando qué está sirviendo el servidor HTTP..."
HTTP_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');

http.get('http://127.0.0.1:3000/', {family: 4, timeout: 10000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
        const versionMatch = data.match(/window\.DASHBOARD_VERSION\s*=\s*['\"]([^'\"]+)['\"]/);
        const supabaseMatch = data.match(/supabase-client\.js\?v=([0-9.]+)/);
        const materialIconsMatch = data.match(/material-icons.*policy/);
        
        console.log('Content-Length:', data.length);
        console.log('Content-Type:', res.headers['content-type']);
        
        if (buildMatch) {
            console.log('BUILD_TIMESTAMP en respuesta HTTP:', buildMatch[1]);
        } else {
            console.log('BUILD_TIMESTAMP: NO encontrado en respuesta HTTP');
        }
        
        if (versionMatch) {
            console.log('DASHBOARD_VERSION en respuesta HTTP:', versionMatch[1]);
        }
        
        if (supabaseMatch) {
            console.log('supabase-client.js versión en respuesta HTTP:', supabaseMatch[1]);
        } else {
            console.log('supabase-client.js: NO encontrado en respuesta HTTP');
        }
        
        if (materialIconsMatch) {
            console.log('Material Icons: Encontrados en respuesta HTTP');
        } else {
            console.log('Material Icons: NO encontrados en respuesta HTTP');
        }
        
        // Comparar con archivo en disco
        try {
            const filePath = path.join('/app', 'dashboard.html');
            const fileContent = fs.readFileSync(filePath, 'utf8');
            const fileBuildMatch = fileContent.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
            
            if (fileBuildMatch && buildMatch) {
                if (fileBuildMatch[1] === buildMatch[1]) {
                    console.log('✅ Archivo en disco y respuesta HTTP COINCIDEN');
                } else {
                    console.log('❌ Archivo en disco y respuesta HTTP NO coinciden');
                    console.log('   Archivo en disco:', fileBuildMatch[1]);
                    console.log('   Respuesta HTTP:', buildMatch[1]);
                }
            }
        } catch (e) {
            console.log('⚠️ No se pudo comparar con archivo en disco');
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

# 3. Verificar si hay múltiples archivos dashboard.html
echo "3️⃣ Buscando múltiples archivos dashboard.html..."
ALL_FILES=$(docker exec "$CONTAINER_ID" find /app -name "dashboard.html" -type f 2>/dev/null)
if [ ! -z "$ALL_FILES" ]; then
    echo "   Archivos encontrados:"
    echo "$ALL_FILES" | while read file; do
        SIZE=$(docker exec "$CONTAINER_ID" stat -c%s "$file" 2>/dev/null || echo "unknown")
        BUILD=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" "$file" 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")
        echo "   - $file ($SIZE bytes, BUILD: $BUILD)"
    done
else
    echo "   ✅ Solo hay un archivo dashboard.html"
fi

echo ""

# 4. Verificar server.js - qué archivo está leyendo
echo "4️⃣ Verificando server.js - qué archivo está leyendo..."
SERVER_JS_CONTENT=$(docker exec "$CONTAINER_ID" cat /app/server.js 2>/dev/null | grep -E "(dashboard\.html|readFile|readFileSync|__dirname|path\.join)" | head -10)
if [ ! -z "$SERVER_JS_CONTENT" ]; then
    echo "   Líneas relevantes en server.js:"
    echo "$SERVER_JS_CONTENT" | sed 's/^/   /'
else
    echo "   ⚠️ No se encontraron referencias a dashboard.html en server.js"
fi

echo ""

# 5. Verificar si Express está usando express.static antes de las rutas específicas
echo "5️⃣ Verificando orden de rutas en server.js..."
ROUTE_ORDER=$(docker exec "$CONTAINER_ID" grep -n -E "(app\.get|app\.use|express\.static)" /app/server.js 2>/dev/null | head -20)
if [ ! -z "$ROUTE_ORDER" ]; then
    echo "   Orden de rutas (primeras 20 líneas):"
    echo "$ROUTE_ORDER" | sed 's/^/   /'
else
    echo "   ⚠️ No se pudo verificar el orden de rutas"
fi

echo ""

# 6. Verificar si hay caché en Node.js
echo "6️⃣ Verificando si hay módulos cacheados..."
CACHED_MODULES=$(docker exec "$CONTAINER_ID" find /app -name "*.js" -path "*/node_modules/.cache/*" 2>/dev/null | head -5)
if [ ! -z "$CACHED_MODULES" ]; then
    echo "   ⚠️ Módulos cacheados encontrados:"
    echo "$CACHED_MODULES" | sed 's/^/   - /'
else
    echo "   ✅ No se encontraron módulos cacheados"
fi

echo ""

# 7. Verificar logs del servidor
echo "7️⃣ Verificando logs recientes del servidor..."
RECENT_LOGS=$(docker logs "$CONTAINER_ID" --tail 30 2>&1 | grep -iE "(dashboard|error|cache|serving)" | tail -10)
if [ ! -z "$RECENT_LOGS" ]; then
    echo "   Logs relevantes:"
    echo "$RECENT_LOGS" | sed 's/^/   /'
else
    echo "   ✅ No hay logs relevantes"
fi

echo ""

# 8. Verificar si Traefik está cacheando
echo "8️⃣ Verificando si Traefik está cacheando..."
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $2}' | head -1)
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    TRAEFIK_LOGS=$(docker service logs "$TRAEFIK_SERVICE" --tail 20 2>&1 | grep -iE "(dashboard|cache|304)" | tail -5)
    if [ ! -z "$TRAEFIK_LOGS" ]; then
        echo "   ⚠️ Logs de Traefik relacionados:"
        echo "$TRAEFIK_LOGS" | sed 's/^/   /'
    else
        echo "   ✅ No hay indicios de caché en Traefik"
    fi
else
    echo "   ⚠️ No se encontró servicio Traefik"
fi

echo ""

# 9. Hacer petición HTTP real desde el host
echo "9️⃣ Haciendo petición HTTP real desde el host..."
if command -v curl &> /dev/null; then
    HTTP_HOST_RESPONSE=$(curl -s -I "https://dashboard.checkin24hs.com" 2>&1 | head -20)
    echo "   Headers de respuesta:"
    echo "$HTTP_HOST_RESPONSE" | sed 's/^/   /'
    
    # Verificar headers de caché
    if echo "$HTTP_HOST_RESPONSE" | grep -qiE "(cache-control|etag|last-modified|304)"; then
        echo "   ⚠️ Headers de caché detectados"
    else
        echo "   ✅ No hay headers de caché problemáticos"
    fi
else
    echo "   ⚠️ curl no está disponible"
fi

echo ""

# 10. Comparar archivo en contenedor con GitHub
echo "🔟 Comparando archivo en contenedor con GitHub..."
TEMP_DIR="/tmp/dashboard_compare_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

curl -L -s "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o github_dashboard.html 2>/dev/null

if [ -f "github_dashboard.html" ]; then
    GITHUB_SIZE=$(stat -c%s github_dashboard.html 2>/dev/null || stat -f%z github_dashboard.html 2>/dev/null)
    GITHUB_BUILD=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" github_dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    
    echo "   GitHub: $GITHUB_SIZE bytes, BUILD: $GITHUB_BUILD"
    echo "   Contenedor: $FILE_SIZE bytes, BUILD: $BUILD_TS_FILE"
    
    if [ "$GITHUB_SIZE" = "$FILE_SIZE" ] && [ "$GITHUB_BUILD" = "$BUILD_TS_FILE" ]; then
        echo "   ✅ Archivo en contenedor coincide con GitHub"
    else
        echo "   ❌ Archivo en contenedor NO coincide con GitHub"
        if [ "$GITHUB_BUILD" != "$BUILD_TS_FILE" ]; then
            echo "   ⚠️ BUILD_TIMESTAMP diferente:"
            echo "      GitHub: $GITHUB_BUILD"
            echo "      Contenedor: $BUILD_TS_FILE"
        fi
    fi
fi

rm -rf "$TEMP_DIR"

echo ""

# 11. Verificar si el servidor está leyendo desde memoria o disco
echo "1️⃣1️⃣ Verificando si hay problema de sincronización..."
# Hacer una modificación temporal al archivo para forzar recarga
docker exec "$CONTAINER_ID" touch /app/dashboard.html 2>/dev/null
sleep 2

# Verificar de nuevo qué está sirviendo
HTTP_RESPONSE2=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
        if (buildMatch) {
            console.log('BUILD_TIMESTAMP después de touch:', buildMatch[1]);
        }
        process.exit(0);
    });
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1)

BUILD_AFTER_TOUCH=$(echo "$HTTP_RESPONSE2" | grep "BUILD_TIMESTAMP después de touch" | cut -d: -f2 | tr -d ' ')
if [ ! -z "$BUILD_AFTER_TOUCH" ]; then
    echo "   BUILD_TIMESTAMP después de touch: $BUILD_AFTER_TOUCH"
    if [ "$BUILD_AFTER_TOUCH" = "$BUILD_TS_FILE" ]; then
        echo "   ✅ El servidor está leyendo del disco correctamente"
    else
        echo "   ❌ El servidor NO está leyendo del disco (puede estar cacheado en memoria)"
    fi
fi

echo ""

echo "=========================================="
echo "📋 RESUMEN Y DIAGNÓSTICO"
echo "=========================================="
echo ""

# Analizar resultados
if [ ! -z "$BUILD_TS_FILE" ]; then
    echo "📊 Estado del archivo en contenedor:"
    echo "   - BUILD_TIMESTAMP: $BUILD_TS_FILE"
    echo "   - Tamaño: $FILE_SIZE bytes"
    echo ""
fi

HTTP_BUILD=$(echo "$HTTP_RESPONSE" | grep "BUILD_TIMESTAMP en respuesta HTTP" | cut -d: -f2 | tr -d ' ')
if [ ! -z "$HTTP_BUILD" ]; then
    echo "📊 Estado de la respuesta HTTP:"
    echo "   - BUILD_TIMESTAMP: $HTTP_BUILD"
    echo ""
    
    if [ "$HTTP_BUILD" != "$BUILD_TS_FILE" ]; then
        echo "❌ PROBLEMA DETECTADO:"
        echo "   El archivo en disco tiene: $BUILD_TS_FILE"
        echo "   Pero el servidor está sirviendo: $HTTP_BUILD"
        echo ""
        echo "   Posibles causas:"
        echo "   1. Express está usando caché en memoria"
        echo "   2. El servidor está leyendo de otra ubicación"
        echo "   3. Hay múltiples archivos dashboard.html"
        echo ""
        echo "   SOLUCIÓN: Reiniciar el servicio para limpiar caché en memoria"
        echo "   docker service update --force $DASHBOARD_SERVICE"
    else
        echo "✅ El servidor está sirviendo el archivo correcto del disco"
        echo ""
        echo "   Si el navegador muestra versión antigua, es problema de CACHÉ del navegador"
        echo ""
        echo "   SOLUCIÓN:"
        echo "   1. Abre ventana de incógnito (Ctrl+Shift+N)"
        echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
        echo "   3. O limpia completamente la caché del navegador"
    fi
fi

HTTP_SUPABASE=$(echo "$HTTP_RESPONSE" | grep "supabase-client.js versión en respuesta HTTP" | cut -d: -f2 | tr -d ' ')
if [ ! -z "$HTTP_SUPABASE" ] && [ "$HTTP_SUPABASE" = "3.1.0" ]; then
    echo "⚠️ PROBLEMA: El servidor está sirviendo supabase-client.js v3.1.0 (antigua)"
    echo "   Esto confirma que está sirviendo una versión antigua del dashboard.html"
fi

echo ""
