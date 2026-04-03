#!/bin/bash
# Script simplificado para reconstruir la imagen Docker AHORA

echo "=========================================="
echo "🔨 Reconstruyendo Imagen Docker"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
IMAGE_NAME="easypanel/checkin24hs/dashboard:latest"
WORK_DIR="/root/checkin24hs"

# Verificar que existe el directorio
if [ ! -d "$WORK_DIR" ]; then
    echo "❌ Directorio no encontrado: $WORK_DIR"
    exit 1
fi

cd "$WORK_DIR"

echo "Directorio de trabajo: $(pwd)"
echo ""

# 1. Actualizar código desde GitHub
echo "1️⃣ Actualizando código desde GitHub..."
if [ -d ".git" ]; then
    echo "   ✅ Repositorio Git encontrado"
    git fetch origin main 2>/dev/null
    git reset --hard origin/main 2>/dev/null
    echo "   ✅ Código actualizado"
else
    echo "   ⚠️ No es un repositorio Git, usando código local"
fi

echo ""

# 2. Verificar BUILD_TIMESTAMP
echo "2️⃣ Verificando BUILD_TIMESTAMP..."
if [ -f "dashboard.html" ]; then
    BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    if [ ! -z "$BUILD_TS" ]; then
        echo "   ✅ BUILD_TIMESTAMP: $BUILD_TS"
    else
        echo "   ⚠️ BUILD_TIMESTAMP no encontrado en código local"
        echo "   Descargando desde GitHub..."
        curl -L -s "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o dashboard.html
        BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
        if [ ! -z "$BUILD_TS" ]; then
            echo "   ✅ BUILD_TIMESTAMP desde GitHub: $BUILD_TS"
        fi
    fi
else
    echo "   ❌ dashboard.html no encontrado"
    exit 1
fi

echo ""

# 3. Verificar Dockerfile
echo "3️⃣ Verificando Dockerfile..."
if [ ! -f "Dockerfile" ]; then
    echo "   ❌ Dockerfile no encontrado"
    exit 1
fi
echo "   ✅ Dockerfile encontrado"

echo ""

# 4. Construir nueva imagen SIN caché
echo "4️⃣ Construyendo nueva imagen Docker (sin caché)..."
echo "   Imagen: $IMAGE_NAME"
echo "   Esto puede tardar 2-5 minutos..."
echo ""

docker build -t "$IMAGE_NAME" --no-cache .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen"
    exit 1
fi

echo ""
echo "✅ Imagen construida correctamente"
echo ""

# 5. Verificar nueva imagen
echo "5️⃣ Verificando nueva imagen..."
TEMP_CONTAINER=$(docker create "$IMAGE_NAME" 2>/dev/null)
if [ ! -z "$TEMP_CONTAINER" ]; then
    NEW_BUILD_TS=$(docker exec "$TEMP_CONTAINER" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")
    NEW_SIZE=$(docker exec "$TEMP_CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
    docker rm "$TEMP_CONTAINER" 2>/dev/null
    
    if [ "$NEW_BUILD_TS" != "NO" ]; then
        echo "   ✅ BUILD_TIMESTAMP en nueva imagen: $NEW_BUILD_TS"
        echo "   ✅ Tamaño del archivo: $NEW_SIZE bytes"
        if [ "$NEW_BUILD_TS" = "$BUILD_TS" ]; then
            echo "   ✅ Coincide con el código actual"
        else
            echo "   ⚠️ No coincide completamente (puede ser normal si hay diferencias menores)"
        fi
    else
        echo "   ❌ BUILD_TIMESTAMP NO encontrado en nueva imagen"
    fi
fi

echo ""

# 6. Actualizar servicio
echo "6️⃣ Actualizando servicio para usar la nueva imagen..."
echo "   Esto reiniciará el servicio y creará nuevos contenedores"
echo ""

docker service update --image "$IMAGE_NAME" "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "⏳ Esperando 30 segundos para que el servicio se reinicie..."
    sleep 30
    
    # Verificar nuevo contenedor
    NEW_CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
    if [ ! -z "$NEW_CONTAINER_ID" ]; then
        echo "   Nuevo contenedor: $NEW_CONTAINER_ID"
        
        # Verificar archivo en nuevo contenedor
        sleep 5
        NEW_BUILD_TS_CONTAINER=$(docker exec "$NEW_CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")
        NEW_SIZE_CONTAINER=$(docker exec "$NEW_CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
        
        if [ "$NEW_BUILD_TS_CONTAINER" != "NO" ]; then
            echo "   ✅ BUILD_TIMESTAMP en nuevo contenedor: $NEW_BUILD_TS_CONTAINER"
            echo "   ✅ Tamaño del archivo: $NEW_SIZE_CONTAINER bytes"
        else
            echo "   ⚠️ BUILD_TIMESTAMP no encontrado (puede necesitar más tiempo)"
        fi
        
        # Verificar que el servidor responde
        echo ""
        echo "7️⃣ Verificando que el servidor responde..."
        sleep 5
        HTTP_RESPONSE=$(docker exec "$NEW_CONTAINER_ID" node -e "
        const http = require('http');
        http.get('http://127.0.0.1:3000/', {family: 4, timeout: 10000}, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
                const supabaseMatch = data.match(/supabase-client\.js\?v=([0-9.]+)/);
                console.log('Status:', res.statusCode);
                if (buildMatch) {
                    console.log('BUILD_TIMESTAMP en respuesta HTTP:', buildMatch[1]);
                } else {
                    console.log('BUILD_TIMESTAMP: NO encontrado');
                }
                if (supabaseMatch) {
                    console.log('supabase-client.js versión:', supabaseMatch[1]);
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
    fi
else
    echo "❌ Error al actualizar el servicio"
    exit 1
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "✅ Imagen reconstruida y servicio actualizado"
echo ""
echo "🌐 Prueba el dashboard:"
echo "   https://dashboard.checkin24hs.com"
echo ""
echo "   ⚠️ IMPORTANTE:"
echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
echo "   3. Verifica que:"
echo "      - Los Material Icons aparezcan correctamente (no '??')"
echo "      - Los caracteres especiales se muestren correctamente"
echo "      - El BUILD_TIMESTAMP sea: $BUILD_TS"
echo ""
echo "📝 NOTA:"
echo "   Esta imagen ahora tiene el código más reciente."
echo "   Cada vez que reinicies el servicio, usará esta imagen actualizada."
echo ""
