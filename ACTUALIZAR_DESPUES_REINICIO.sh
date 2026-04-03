#!/bin/bash
# Script para actualizar dashboard.html DESPUÉS de que el servicio se reinicie

echo "=========================================="
echo "🔄 Actualizando dashboard.html después del reinicio"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

# Esperar a que el servicio se reinicie completamente
echo "1️⃣ Esperando a que el servicio se reinicie completamente..."
sleep 10

# Obtener el nuevo contenedor
NEW_CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$NEW_CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "   Esperando 20 segundos más..."
    sleep 20
    NEW_CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
    
    if [ -z "$NEW_CONTAINER_ID" ]; then
        echo "❌ Aún no se encontró contenedor"
        exit 1
    fi
fi

echo "   Nuevo contenedor: $NEW_CONTAINER_ID"
echo ""

# Verificar que el contenedor está listo
echo "2️⃣ Verificando que el contenedor está listo..."
sleep 5

SERVER_READY=$(docker exec "$NEW_CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    process.exit(1);
});
" 2>&1)

if [ $? -ne 0 ]; then
    echo "⚠️ El servidor aún no está listo, esperando 10 segundos más..."
    sleep 10
fi

echo "✅ Contenedor listo"
echo ""

# Crear directorio temporal
TEMP_DIR="/tmp/dashboard_post_restart_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "3️⃣ Descargando dashboard.html desde GitHub..."
curl -L -o dashboard.html "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" 2>/dev/null

if [ ! -f "dashboard.html" ]; then
    echo "❌ Error al descargar dashboard.html"
    rm -rf "$TEMP_DIR"
    exit 1
fi

FILE_SIZE=$(stat -c%s dashboard.html 2>/dev/null || stat -f%z dashboard.html 2>/dev/null)
echo "✅ Archivo descargado: $FILE_SIZE bytes"

# Verificar BUILD_TIMESTAMP
BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
echo "✅ BUILD_TIMESTAMP: $BUILD_TS"

echo ""

# Hacer backup
echo "4️⃣ Haciendo backup del archivo actual en el nuevo contenedor..."
docker exec "$NEW_CONTAINER_ID" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"

echo ""

# Copiar al nuevo contenedor usando tar
echo "5️⃣ Copiando archivo al nuevo contenedor (método tar)..."
tar cf dashboard.tar dashboard.html
docker cp dashboard.tar "$NEW_CONTAINER_ID:/tmp/"
docker exec "$NEW_CONTAINER_ID" tar xf /tmp/dashboard.tar -C /app/
docker exec "$NEW_CONTAINER_ID" rm /tmp/dashboard.tar

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar, intentando método directo..."
    docker cp dashboard.html "$NEW_CONTAINER_ID:/app/dashboard.html"
fi

echo "✅ Archivo copiado"

echo ""

# Verificar que se copió correctamente
echo "6️⃣ Verificando archivo copiado..."
sleep 2

NEW_SIZE=$(docker exec "$NEW_CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$NEW_CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño en contenedor: $NEW_SIZE bytes"
echo "   Tamaño esperado: $FILE_SIZE bytes"

if [ "$NEW_SIZE" != "$FILE_SIZE" ]; then
    echo "   ⚠️ Los tamaños no coinciden, intentando copiar de nuevo..."
    docker cp dashboard.html "$NEW_CONTAINER_ID:/app/dashboard.html"
    sleep 2
    NEW_SIZE=$(docker exec "$NEW_CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$NEW_CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   Tamaño después de segunda copia: $NEW_SIZE bytes"
fi

# Verificar BUILD_TIMESTAMP
NEW_BUILD_TS=$(docker exec "$NEW_CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"")
if [ ! -z "$NEW_BUILD_TS" ]; then
    echo "   ✅ BUILD_TIMESTAMP: $NEW_BUILD_TS"
    
    if [ "$NEW_BUILD_TS" = "$BUILD_TS" ]; then
        echo "   ✅ BUILD_TIMESTAMP coincide con el esperado"
    else
        echo "   ⚠️ BUILD_TIMESTAMP no coincide (esperado: $BUILD_TS, encontrado: $NEW_BUILD_TS)"
    fi
else
    echo "   ❌ BUILD_TIMESTAMP NO encontrado"
fi

# Verificar Material Icons
if docker exec "$NEW_CONTAINER_ID" grep -q "material-icons.*policy" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ Material Icons encontrados (tiene iconos de políticas)"
else
    echo "   ⚠️ Material Icons pueden no estar presentes"
fi

echo ""

# Verificar permisos
echo "7️⃣ Verificando permisos..."
docker exec "$NEW_CONTAINER_ID" chmod 644 /app/dashboard.html 2>/dev/null
echo "✅ Permisos verificados"

echo ""

# Verificar que el servidor responde con la versión nueva
echo "8️⃣ Verificando que el servidor responde con la versión nueva..."
sleep 3
SERVER_RESPONSE=$(docker exec "$NEW_CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 10000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
        const versionMatch = data.match(/window\.DASHBOARD_VERSION\s*=\s*['\"]([^'\"]+)['\"]/);
        const materialIconsMatch = data.match(/material-icons.*policy/);
        console.log('Status:', res.statusCode);
        if (buildMatch) {
            console.log('BUILD_TIMESTAMP en respuesta:', buildMatch[1]);
        } else {
            console.log('BUILD_TIMESTAMP: NO encontrado');
        }
        if (versionMatch) {
            console.log('DASHBOARD_VERSION en respuesta:', versionMatch[1]);
        }
        if (materialIconsMatch) {
            console.log('Material Icons: Encontrados');
        } else {
            console.log('Material Icons: No encontrados en respuesta');
        }
        process.exit(0);
    });
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1)

echo "$SERVER_RESPONSE" | while read line; do
    echo "   $line"
done

echo ""

# Limpiar
echo "9️⃣ Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if echo "$SERVER_RESPONSE" | grep -q "BUILD_TIMESTAMP en respuesta: $BUILD_TS"; then
    echo "✅ Dashboard actualizado correctamente"
    echo ""
    echo "📊 Información:"
    echo "   - BUILD_TIMESTAMP: $BUILD_TS"
    echo "   - Contenedor: $NEW_CONTAINER_ID"
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
    echo "      - Los logs de consola NO tengan '?' en lugar de caracteres especiales"
else
    BUILD_HTTP=$(echo "$SERVER_RESPONSE" | grep "BUILD_TIMESTAMP en respuesta" | cut -d: -f2 | tr -d ' ')
    if [ ! -z "$BUILD_HTTP" ]; then
        echo "⚠️ El servidor está sirviendo BUILD_TIMESTAMP: $BUILD_HTTP"
        echo "   Esperado: $BUILD_TS"
        echo ""
        echo "   El servidor puede necesitar más tiempo para recargar el archivo"
        echo "   Espera 30 segundos y prueba de nuevo en el navegador"
    else
        echo "❌ El servidor no está sirviendo BUILD_TIMESTAMP"
        echo "   Verifica manualmente: docker exec $NEW_CONTAINER_ID grep 'BUILD_TIMESTAMP' /app/dashboard.html | head -1"
    fi
fi

echo ""
