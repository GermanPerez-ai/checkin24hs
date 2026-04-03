#!/bin/bash
# Script completo para verificar qué versión está realmente en el contenedor

echo "=========================================="
echo "🔍 VERIFICACIÓN COMPLETA DE VERSIÓN"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "📋 Contenedores corriendo:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -i dashboard || echo "   Ninguno encontrado"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

echo "2️⃣ Verificando BUILD_TIMESTAMP en dashboard.html del contenedor..."
DASHBOARD_PATH="/app/dashboard.html"

if docker exec "$CONTAINER_ID" test -f "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Archivo encontrado en: $DASHBOARD_PATH"
    
    # Extraer BUILD_TIMESTAMP (múltiples métodos para ser más robusto)
    BUILD_TIMESTAMP=$(docker exec "$CONTAINER_ID" grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" "$DASHBOARD_PATH" 2>/dev/null | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    
    # Si no funciona con grep -oP, intentar con sed
    if [ -z "$BUILD_TIMESTAMP" ]; then
        BUILD_TIMESTAMP=$(docker exec "$CONTAINER_ID" grep "window.BUILD_TIMESTAMP" "$DASHBOARD_PATH" 2>/dev/null | sed -n "s/.*window\.BUILD_TIMESTAMP = ['\"]\([^'\"]*\)['\"].*/\1/p" | head -1)
    fi
    
    # Si aún no funciona, intentar con awk
    if [ -z "$BUILD_TIMESTAMP" ]; then
        BUILD_TIMESTAMP=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" "$DASHBOARD_PATH" 2>/dev/null | awk -F"'" '{print $2}' | head -1)
    fi
    
    # Mostrar las primeras líneas del archivo para debug
    if [ -z "$BUILD_TIMESTAMP" ]; then
        echo "⚠️ No se encontró BUILD_TIMESTAMP con regex, mostrando primeras líneas del archivo:"
        docker exec "$CONTAINER_ID" head -20 "$DASHBOARD_PATH" 2>/dev/null | grep -i "build\|version\|timestamp" | head -5
    fi
    
    if [ -z "$BUILD_TIMESTAMP" ]; then
        echo "❌ No se encontró BUILD_TIMESTAMP en el archivo"
        echo "   Esto indica que el contenedor tiene una versión MUY ANTIGUA"
    else
        echo "✅ BUILD_TIMESTAMP en contenedor: $BUILD_TIMESTAMP"
        
        # Extraer fecha
        BUILD_DATE=$(echo "$BUILD_TIMESTAMP" | cut -d'T' -f1)
        TODAY_DATE=$(date +%Y-%m-%d)
        
        echo "   Fecha del build: $BUILD_DATE"
        echo "   Fecha de hoy: $TODAY_DATE"
        
        if [ "$BUILD_DATE" = "$TODAY_DATE" ]; then
            echo "✅ El build es de HOY"
        else
            echo "❌ El build NO es de hoy (es de $BUILD_DATE)"
        fi
    fi
    
    # Extraer DASHBOARD_VERSION (múltiples métodos)
    DASHBOARD_VERSION=$(docker exec "$CONTAINER_ID" grep -oP "window\.DASHBOARD_VERSION = ['\"]([^'\"]+)['\"]" "$DASHBOARD_PATH" 2>/dev/null | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    
    # Si no funciona, intentar con sed
    if [ -z "$DASHBOARD_VERSION" ]; then
        DASHBOARD_VERSION=$(docker exec "$CONTAINER_ID" grep "window.DASHBOARD_VERSION" "$DASHBOARD_PATH" 2>/dev/null | sed -n "s/.*window\.DASHBOARD_VERSION = ['\"]\([^'\"]*\)['\"].*/\1/p" | head -1)
    fi
    
    # Si aún no funciona, intentar con awk
    if [ -z "$DASHBOARD_VERSION" ]; then
        DASHBOARD_VERSION=$(docker exec "$CONTAINER_ID" grep "DASHBOARD_VERSION" "$DASHBOARD_PATH" 2>/dev/null | awk -F"'" '{print $2}' | head -1)
    fi
    
    if [ -z "$DASHBOARD_VERSION" ]; then
        echo "❌ No se encontró DASHBOARD_VERSION en el archivo"
    else
        echo "✅ DASHBOARD_VERSION en contenedor: $DASHBOARD_VERSION"
    fi
else
    echo "❌ No se encontró dashboard.html en $DASHBOARD_PATH"
    echo "📋 Listando archivos en /app:"
    docker exec "$CONTAINER_ID" ls -la /app 2>/dev/null | head -20
fi

echo ""
echo "3️⃣ Verificando versión desde el endpoint /api/version..."
API_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/api/version', {family: 4, timeout: 5000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            console.log('Version:', json.version);
            console.log('BuildTimestamp:', json.buildTimestamp);
        } catch(e) {
            console.error('Error:', e.message);
        }
    });
}).on('error', (err) => {
    console.error('Error:', err.message);
});
" 2>&1)

if [ $? -eq 0 ]; then
    echo "$API_RESPONSE"
else
    echo "❌ No se pudo consultar el endpoint /api/version"
fi

echo ""
echo "4️⃣ Verificando imagen Docker..."
IMAGE_NAME=$(docker inspect "$CONTAINER_ID" --format '{{.Config.Image}}' 2>/dev/null)
echo "Imagen: $IMAGE_NAME"

# Verificar fecha de creación de la imagen
IMAGE_CREATED=$(docker inspect "$IMAGE_NAME" --format '{{.Created}}' 2>/dev/null 2>/dev/null)
if [ ! -z "$IMAGE_CREATED" ]; then
    echo "Fecha de creación de la imagen: $IMAGE_CREATED"
fi

echo ""
echo "5️⃣ Verificando servicio Docker Swarm..."
SERVICE_IMAGE=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)
echo "Imagen del servicio: $SERVICE_IMAGE"

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ ! -z "$BUILD_TIMESTAMP" ]; then
    BUILD_DATE=$(echo "$BUILD_TIMESTAMP" | cut -d'T' -f1)
    TODAY_DATE=$(date +%Y-%m-%d)
    
    if [ "$BUILD_DATE" = "$TODAY_DATE" ]; then
        echo "✅ El contenedor tiene la versión de HOY"
        echo "   BUILD_TIMESTAMP: $BUILD_TIMESTAMP"
    else
        echo "❌ El contenedor tiene una versión ANTIGUA"
        echo "   BUILD_TIMESTAMP: $BUILD_TIMESTAMP (fecha: $BUILD_DATE)"
        echo "   Fecha de hoy: $TODAY_DATE"
        echo ""
        echo "🔧 SOLUCIÓN:"
        echo "   1. Ve a EasyPanel"
        echo "   2. Servicio: dashboard"
        echo "   3. Haz clic en 'Deploy' o 'Redeploy'"
        echo "   4. Si tiene opción 'Build without cache', actívala"
        echo "   5. Espera 3-5 minutos"
    fi
else
    echo "❌ PROBLEMA CRÍTICO: No se pudo encontrar BUILD_TIMESTAMP"
    echo ""
    echo "   Esto significa que el contenedor tiene una versión MUY ANTIGUA"
    echo "   (anterior a cuando se implementó BUILD_TIMESTAMP)"
    echo ""
    echo "🔧 SOLUCIÓN URGENTE:"
    echo "   1. Ve a EasyPanel"
    echo "   2. Servicio: dashboard"
    echo "   3. Pestaña 'Source' o 'Fuente'"
    echo "   4. Verifica que:"
    echo "      - Repositorio: GermanPerez-ai/checkin24hs"
    echo "      - Rama: main"
    echo "      - Build Path: /"
    echo "   5. Haz clic en 'Deploy' o 'Redeploy'"
    echo "   6. Si tiene opción 'Build without cache', actívala"
    echo "   7. Espera 3-5 minutos"
    echo ""
    echo "   La imagen fue creada: 2026-01-13T01:18:29Z"
    echo "   (hace más de 1 hora, necesita actualización)"
fi

echo ""
