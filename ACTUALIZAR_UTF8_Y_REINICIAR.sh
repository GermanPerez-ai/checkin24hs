#!/bin/bash
# Script para actualizar dashboard.html con codificación UTF-8 correcta y reiniciar

echo "=========================================="
echo "🔄 Actualizando dashboard.html con UTF-8 correcto"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor actual: $CONTAINER_ID"
echo ""

# Crear directorio temporal
TEMP_DIR="/tmp/dashboard_utf8_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "1️⃣ Descargando dashboard.html desde GitHub..."
curl -L -o dashboard.html "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" 2>/dev/null

if [ ! -f "dashboard.html" ]; then
    echo "❌ Error al descargar dashboard.html"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verificar codificación del archivo descargado
FILE_ENCODING=$(file -bi dashboard.html 2>/dev/null | grep -oP "charset=\K[^;]+" || echo "unknown")
echo "   Codificación del archivo: $FILE_ENCODING"

# Forzar codificación UTF-8
if command -v iconv &> /dev/null; then
    echo "   Convirtiendo a UTF-8 explícitamente..."
    iconv -f UTF-8 -t UTF-8 dashboard.html > dashboard_utf8.html 2>/dev/null
    if [ $? -eq 0 ] && [ -f "dashboard_utf8.html" ]; then
        mv dashboard_utf8.html dashboard.html
        echo "   ✅ Conversión completada"
    fi
fi

FILE_SIZE=$(stat -c%s dashboard.html 2>/dev/null || stat -f%z dashboard.html 2>/dev/null)
echo "✅ Archivo descargado: $FILE_SIZE bytes"

# Verificar que tiene BUILD_TIMESTAMP
if ! grep -q "BUILD_TIMESTAMP" dashboard.html; then
    echo "❌ El archivo descargado NO tiene BUILD_TIMESTAMP"
    rm -rf "$TEMP_DIR"
    exit 1
fi

BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
echo "✅ BUILD_TIMESTAMP: $BUILD_TS"

# Verificar UTF-8
if grep -q "VERSIÓN:" dashboard.html; then
    echo "✅ UTF-8 correcto (tiene 'VERSIÓN' con tilde)"
else
    echo "⚠️ Puede haber problema de UTF-8"
fi

echo ""

# Hacer backup
echo "2️⃣ Haciendo backup del archivo actual..."
docker exec "$CONTAINER_ID" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"

echo ""

# Copiar al contenedor usando tar para preservar codificación
echo "3️⃣ Copiando archivo al contenedor (método tar para preservar UTF-8)..."
tar cf dashboard.tar dashboard.html
docker cp dashboard.tar "$CONTAINER_ID:/tmp/"
docker exec "$CONTAINER_ID" tar xf /tmp/dashboard.tar -C /app/
docker exec "$CONTAINER_ID" rm /tmp/dashboard.tar

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar el archivo"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "✅ Archivo copiado"

echo ""

# Verificar que se copió correctamente
echo "4️⃣ Verificando archivo copiado..."
sleep 2

NEW_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño en contenedor: $NEW_SIZE bytes"
echo "   Tamaño esperado: $FILE_SIZE bytes"

if [ "$NEW_SIZE" != "$FILE_SIZE" ]; then
    echo "   ⚠️ Los tamaños no coinciden, intentando método directo..."
    docker cp dashboard.html "$CONTAINER_ID:/app/dashboard.html"
    sleep 2
    NEW_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   Tamaño después de copia directa: $NEW_SIZE bytes"
fi

# Verificar BUILD_TIMESTAMP
NEW_BUILD_TS=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1)
if [ -z "$NEW_BUILD_TS" ]; then
    echo "   ❌ BUILD_TIMESTAMP NO encontrado después de copiar"
    rm -rf "$TEMP_DIR"
    exit 1
else
    echo "   ✅ BUILD_TIMESTAMP encontrado"
fi

# Verificar UTF-8 en el contenedor
if docker exec "$CONTAINER_ID" grep -q "VERSIÓN:" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ UTF-8 correcto en contenedor (tiene 'VERSIÓN')"
else
    echo "   ⚠️ UTF-8 puede estar incorrecto en contenedor"
fi

echo ""

# Verificar permisos
echo "5️⃣ Verificando permisos..."
docker exec "$CONTAINER_ID" chmod 644 /app/dashboard.html 2>/dev/null
echo "✅ Permisos verificados"

echo ""

# Reiniciar el servicio
echo "6️⃣ Reiniciando el servicio para que lea el archivo nuevo..."
docker service update --force "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
    echo ""
    echo "⏳ Esperando 30 segundos para que el servicio se inicie completamente..."
    sleep 30
else
    echo "❌ Error al reiniciar el servicio"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""

# Verificar nuevo contenedor
echo "7️⃣ Verificando nuevo contenedor..."
NEW_CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$NEW_CONTAINER_ID" ]; then
    echo "❌ No se encontró nuevo contenedor"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "   Nuevo contenedor: $NEW_CONTAINER_ID"

# Verificar archivo en nuevo contenedor
NEW_SIZE2=$(docker exec "$NEW_CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$NEW_CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño del archivo: $NEW_SIZE2 bytes"

NEW_BUILD_TS2=$(docker exec "$NEW_CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"")
if [ ! -z "$NEW_BUILD_TS2" ]; then
    echo "   ✅ BUILD_TIMESTAMP: $NEW_BUILD_TS2"
else
    echo "   ❌ BUILD_TIMESTAMP NO encontrado"
fi

# Verificar UTF-8
if docker exec "$NEW_CONTAINER_ID" grep -q "VERSIÓN:" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ UTF-8 correcto (tiene 'VERSIÓN')"
else
    echo "   ⚠️ UTF-8 puede estar incorrecto"
fi

echo ""

# Verificar que el servidor responde
echo "8️⃣ Verificando que el servidor responde..."
sleep 5
SERVER_RESPONSE=$(docker exec "$NEW_CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 10000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
        const versionMatch = data.match(/window\.DASHBOARD_VERSION\s*=\s*['\"]([^'\"]+)['\"]/);
        const utf8Match = data.match(/VERSI[ÓO]N:/);
        console.log('Status:', res.statusCode);
        if (buildMatch) {
            console.log('BUILD_TIMESTAMP en respuesta:', buildMatch[1]);
        } else {
            console.log('BUILD_TIMESTAMP: NO encontrado');
        }
        if (versionMatch) {
            console.log('DASHBOARD_VERSION en respuesta:', versionMatch[1]);
        }
        if (utf8Match) {
            console.log('UTF-8: Correcto (tiene VERSIÓN)');
        } else {
            console.log('UTF-8: Puede estar incorrecto');
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

if echo "$SERVER_RESPONSE" | grep -q "BUILD_TIMESTAMP en respuesta" && echo "$SERVER_RESPONSE" | grep -q "UTF-8: Correcto"; then
    BUILD_HTTP=$(echo "$SERVER_RESPONSE" | grep "BUILD_TIMESTAMP en respuesta" | cut -d: -f2 | tr -d ' ')
    echo "✅ Dashboard actualizado con UTF-8 correcto"
    echo ""
    echo "📊 Información:"
    echo "   - BUILD_TIMESTAMP: $BUILD_HTTP"
    echo "   - UTF-8: Correcto"
    echo "   - Nuevo contenedor: $NEW_CONTAINER_ID"
    echo ""
    echo "🌐 Prueba el dashboard:"
    echo "   https://dashboard.checkin24hs.com"
    echo ""
    echo "   ⚠️ IMPORTANTE:"
    echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
    echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
    echo "   3. Verifica que los caracteres especiales se muestren correctamente"
    echo "   4. Los logs de consola NO deberían tener '?' en lugar de caracteres especiales"
else
    echo "⚠️ Puede haber problemas con UTF-8"
    echo ""
    echo "   Espera 1-2 minutos más y prueba de nuevo"
    echo "   O verifica manualmente en el navegador"
fi

echo ""
