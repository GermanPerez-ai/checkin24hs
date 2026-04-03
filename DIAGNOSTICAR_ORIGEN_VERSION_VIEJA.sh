#!/bin/bash
# Script para diagnosticar de dónde viene la versión vieja

echo "=========================================="
echo "🔍 Diagnosticando origen de versión vieja"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
EXPECTED_BUILD="2026-01-12T20:37:50Z"
EXPECTED_VERSION="2.1.0"

# 1. Verificar versión en el archivo local (GitHub)
echo "1️⃣ Verificando versión en GitHub (archivo local)..."
if [ -f "dashboard.html" ]; then
    LOCAL_BUILD=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    LOCAL_VERSION=$(grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    echo "   ✅ Archivo local encontrado"
    echo "   📋 BUILD_TIMESTAMP local: $LOCAL_BUILD"
    echo "   📋 VERSION local: $LOCAL_VERSION"
    
    if [ "$LOCAL_BUILD" = "$EXPECTED_BUILD" ]; then
        echo "   ✅ BUILD_TIMESTAMP local es CORRECTO"
    else
        echo "   ❌ BUILD_TIMESTAMP local es INCORRECTO (esperado: $EXPECTED_BUILD)"
    fi
else
    echo "   ⚠️ Archivo local no encontrado (esto es normal si se ejecuta en el servidor)"
fi

echo ""

# 2. Verificar versión en el contenedor del servidor
echo "2️⃣ Verificando versión en el contenedor del servidor..."
CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "   ❌ No se encontró contenedor del dashboard"
    echo "   Verificando servicios..."
    docker service ls | grep dashboard
    exit 1
fi

echo "   ✅ Contenedor encontrado: $CONTAINER"

# Verificar BUILD_TIMESTAMP en el contenedor
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")

if [ -z "$CONTAINER_BUILD" ]; then
    echo "   ❌ No se pudo leer BUILD_TIMESTAMP del contenedor"
    echo "   Verificando si el archivo existe..."
    docker exec "$CONTAINER" ls -la /app/dashboard.html 2>/dev/null || echo "   ❌ Archivo dashboard.html no existe en el contenedor"
else
    echo "   📋 BUILD_TIMESTAMP en contenedor: $CONTAINER_BUILD"
    
    if [ "$CONTAINER_BUILD" = "$EXPECTED_BUILD" ]; then
        echo "   ✅ BUILD_TIMESTAMP en contenedor es CORRECTO"
    else
        echo "   ❌ BUILD_TIMESTAMP en contenedor es INCORRECTO"
        echo "   ⚠️ El contenedor tiene una versión ANTIGUA"
        echo "   💡 Solución: Haz un nuevo deploy en EasyPanel"
    fi
fi

# Verificar VERSION en el contenedor
CONTAINER_VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")

if [ ! -z "$CONTAINER_VERSION" ]; then
    echo "   📋 VERSION en contenedor: $CONTAINER_VERSION"
    
    if [ "$CONTAINER_VERSION" = "$EXPECTED_VERSION" ]; then
        echo "   ✅ VERSION en contenedor es CORRECTO"
    else
        echo "   ❌ VERSION en contenedor es INCORRECTO"
    fi
fi

echo ""

# 3. Verificar qué devuelve el endpoint /api/version
echo "3️⃣ Verificando endpoint /api/version..."
API_RESPONSE=$(docker exec "$CONTAINER" curl -s http://localhost:3000/api/version 2>/dev/null)

if [ -z "$API_RESPONSE" ]; then
    echo "   ❌ No se pudo obtener respuesta del endpoint /api/version"
else
    echo "   ✅ Respuesta del endpoint:"
    echo "$API_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$API_RESPONSE"
    
    API_BUILD=$(echo "$API_RESPONSE" | grep -oP '"buildTimestamp":\s*"([^"]+)"' | grep -oP '"[^"]+"' | tr -d '"')
    API_VERSION=$(echo "$API_RESPONSE" | grep -oP '"version":\s*"([^"]+)"' | grep -oP '"[^"]+"' | tr -d '"')
    
    if [ ! -z "$API_BUILD" ]; then
        echo "   📋 BUILD_TIMESTAMP del API: $API_BUILD"
        if [ "$API_BUILD" = "$EXPECTED_BUILD" ]; then
            echo "   ✅ BUILD_TIMESTAMP del API es CORRECTO"
        else
            echo "   ❌ BUILD_TIMESTAMP del API es INCORRECTO"
        fi
    fi
    
    if [ ! -z "$API_VERSION" ]; then
        echo "   📋 VERSION del API: $API_VERSION"
        if [ "$API_VERSION" = "$EXPECTED_VERSION" ]; then
            echo "   ✅ VERSION del API es CORRECTO"
        else
            echo "   ❌ VERSION del API es INCORRECTO"
        fi
    fi
fi

echo ""

# 4. Verificar fecha de modificación del archivo en el contenedor
echo "4️⃣ Verificando fecha de modificación del archivo en el contenedor..."
FILE_DATE=$(docker exec "$CONTAINER" stat -c %y /app/dashboard.html 2>/dev/null | cut -d' ' -f1)

if [ ! -z "$FILE_DATE" ]; then
    echo "   📋 Fecha de modificación: $FILE_DATE"
    TODAY=$(date +%Y-%m-%d)
    if [ "$FILE_DATE" = "$TODAY" ]; then
        echo "   ✅ El archivo fue modificado HOY"
    else
        echo "   ⚠️ El archivo NO fue modificado hoy (última modificación: $FILE_DATE)"
    fi
fi

echo ""

# 5. Verificar si Traefik está cacheando
echo "5️⃣ Verificando si Traefik está cacheando..."
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep traefik | head -1)

if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "   ✅ Contenedor Traefik encontrado: $TRAEFIK_CONTAINER"
    echo "   📋 Verificando logs de Traefik para errores de caché..."
    TRAEFIK_LOGS=$(docker logs "$TRAEFIK_CONTAINER" --tail 50 2>&1 | grep -iE "(cache|cached|304|not modified)" | tail -5)
    
    if [ -z "$TRAEFIK_LOGS" ]; then
        echo "   ✅ No se encontraron indicios de caché en Traefik"
    else
        echo "   ⚠️ Posibles indicios de caché en Traefik:"
        echo "$TRAEFIK_LOGS"
    fi
else
    echo "   ⚠️ No se encontró contenedor de Traefik"
fi

echo ""

# 6. Verificar headers que envía el servidor
echo "6️⃣ Verificando headers que envía el servidor..."
HEADERS=$(docker exec "$CONTAINER" curl -s -I http://localhost:3000/ 2>/dev/null | grep -iE "(cache-control|pragma|expires|etag|last-modified)")

if [ ! -z "$HEADERS" ]; then
    echo "   ✅ Headers de respuesta:"
    echo "$HEADERS" | sed 's/^/   /'
    
    if echo "$HEADERS" | grep -qi "no-cache"; then
        echo "   ✅ Headers anti-caché presentes"
    else
        echo "   ⚠️ Headers anti-caché NO encontrados"
    fi
else
    echo "   ⚠️ No se pudieron obtener los headers"
fi

echo ""

# 7. Resumen y diagnóstico
echo "=========================================="
echo "📋 RESUMEN Y DIAGNÓSTICO"
echo "=========================================="
echo ""

if [ "$CONTAINER_BUILD" = "$EXPECTED_BUILD" ]; then
    echo "✅ El contenedor tiene la versión CORRECTA"
    echo ""
    echo "💡 Si el navegador muestra versión antigua, el problema es:"
    echo "   1. Caché del navegador (localStorage, sessionStorage, HTTP cache)"
    echo "   2. Service Worker (aunque no se encontró ninguno)"
    echo "   3. Proxy/CDN intermedio cacheando"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   1. Limpia completamente la caché del navegador"
    echo "   2. Usa modo incógnito"
    echo "   3. Con DevTools abierto, marca 'Disable cache'"
    echo "   4. Recarga con Ctrl+Shift+R"
else
    echo "❌ El contenedor tiene una versión ANTIGUA"
    echo ""
    echo "💡 El problema está en el servidor/contenedor"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   1. Ve a EasyPanel"
    echo "   2. Haz clic en 'Deploy' o 'Redeploy'"
    echo "   3. Espera 3-5 minutos"
    echo "   4. Ejecuta este script de nuevo para verificar"
    echo ""
    echo "   O si el problema persiste:"
    echo "   1. Elimina el servicio en EasyPanel"
    echo "   2. Crea un nuevo servicio con la misma configuración"
    echo "   3. Haz deploy"
fi

echo ""
echo "=========================================="
echo "🔍 COMANDOS PARA VERIFICAR EN EL NAVEGADOR"
echo "=========================================="
echo ""
echo "Abre la consola del navegador (F12) y ejecuta:"
echo ""
echo "// Ver versión actual"
echo "console.log('Versión:', window.DASHBOARD_VERSION);"
echo "console.log('Build:', window.BUILD_TIMESTAMP);"
echo ""
echo "// Ver versión almacenada en localStorage"
echo "console.log('Versión almacenada:', localStorage.getItem('dashboard_version'));"
echo "console.log('Build almacenado:', localStorage.getItem('dashboard_build_timestamp'));"
echo ""
echo "// Verificar endpoint del servidor"
echo "fetch('/api/version').then(r => r.json()).then(console.log);"
echo ""
echo "// Limpiar todo y forzar recarga"
echo "localStorage.clear(); sessionStorage.clear(); location.reload(true);"
echo ""
