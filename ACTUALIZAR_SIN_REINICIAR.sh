#!/bin/bash
# Script para actualizar dashboard.html SIN reiniciar el servicio
# Esto evita que Docker Swarm cree un nuevo contenedor desde la imagen antigua

echo "=========================================="
echo "🔄 Actualizando dashboard.html SIN reiniciar"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor actual: $CONTAINER_ID"
echo "⚠️ IMPORTANTE: NO reiniciaremos el servicio para evitar que se cree un nuevo contenedor"
echo ""

# Crear directorio temporal
TEMP_DIR="/tmp/dashboard_no_restart_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "1️⃣ Descargando dashboard.html desde GitHub..."
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

# Verificar Material Icons
if grep -q "material-icons.*policy" dashboard.html; then
    echo "✅ Material Icons encontrados"
else
    echo "⚠️ Material Icons no encontrados"
fi

echo ""

# Verificar archivo actual en contenedor
echo "2️⃣ Verificando archivo actual en contenedor..."
CURRENT_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
CURRENT_BUILD=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")

echo "   Tamaño actual: $CURRENT_SIZE bytes"
echo "   BUILD_TIMESTAMP actual: $CURRENT_BUILD"

if [ "$CURRENT_SIZE" = "$FILE_SIZE" ] && [ "$CURRENT_BUILD" = "$BUILD_TS" ]; then
    echo "   ✅ El archivo ya está actualizado"
    rm -rf "$TEMP_DIR"
    exit 0
fi

echo ""

# Hacer backup
echo "3️⃣ Haciendo backup del archivo actual..."
docker exec "$CONTAINER_ID" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"

echo ""

# Copiar al contenedor usando tar
echo "4️⃣ Copiando archivo al contenedor (método tar)..."
tar cf dashboard.tar dashboard.html
docker cp dashboard.tar "$CONTAINER_ID:/tmp/"
docker exec "$CONTAINER_ID" tar xf /tmp/dashboard.tar -C /app/
docker exec "$CONTAINER_ID" rm /tmp/dashboard.tar

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar, intentando método directo..."
    docker cp dashboard.html "$CONTAINER_ID:/app/dashboard.html"
fi

echo "✅ Archivo copiado"

echo ""

# Verificar que se copió correctamente
echo "5️⃣ Verificando archivo copiado..."
sleep 2

NEW_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño en contenedor: $NEW_SIZE bytes"
echo "   Tamaño esperado: $FILE_SIZE bytes"

if [ "$NEW_SIZE" != "$FILE_SIZE" ]; then
    echo "   ⚠️ Los tamaños no coinciden, intentando copiar de nuevo..."
    docker cp dashboard.html "$CONTAINER_ID:/app/dashboard.html"
    sleep 2
    NEW_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   Tamaño después de segunda copia: $NEW_SIZE bytes"
fi

# Verificar BUILD_TIMESTAMP
NEW_BUILD_TS=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"")
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
if docker exec "$CONTAINER_ID" grep -q "material-icons.*policy" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ Material Icons encontrados"
else
    echo "   ⚠️ Material Icons no encontrados"
fi

echo ""

# Verificar permisos
echo "6️⃣ Verificando permisos..."
docker exec "$CONTAINER_ID" chmod 644 /app/dashboard.html 2>/dev/null
echo "✅ Permisos verificados"

echo ""

# Forzar recarga del archivo en Node.js (sin reiniciar el servicio)
echo "7️⃣ Forzando recarga del archivo en Node.js..."
# Tocar el archivo para cambiar su timestamp
docker exec "$CONTAINER_ID" touch /app/dashboard.html 2>/dev/null

# Si el servidor está usando require.cache, necesitamos reiniciar el proceso Node.js
# Pero no queremos reiniciar el contenedor completo
# Intentar enviar señal SIGHUP al proceso Node.js principal
NODE_PID=$(docker exec "$CONTAINER_ID" pgrep -f "node.*server.js" | head -1)
if [ ! -z "$NODE_PID" ]; then
    echo "   Proceso Node.js encontrado: PID $NODE_PID"
    echo "   ⚠️ No podemos reiniciar el proceso sin reiniciar el contenedor"
    echo "   El servidor debería recargar el archivo en la próxima petición"
else
    echo "   ⚠️ No se encontró proceso Node.js"
fi

echo ""

# Verificar que el servidor responde
echo "8️⃣ Verificando que el servidor responde..."
sleep 3
SERVER_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 10000}, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        const buildMatch = data.match(/window\.BUILD_TIMESTAMP\s*=\s*['\"]([^'\"]+)['\"]/);
        const versionMatch = data.match(/window\.DASHBOARD_VERSION\s*=\s*['\"]([^'\"]+)['\"]/);
        const supabaseMatch = data.match(/supabase-client\.js\?v=([0-9.]+)/);
        const materialIconsMatch = data.match(/material-icons.*policy/);
        
        console.log('Status:', res.statusCode);
        console.log('Content-Length:', data.length);
        
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
        }
        
        if (materialIconsMatch) {
            console.log('Material Icons: Encontrados en respuesta HTTP');
        } else {
            console.log('Material Icons: NO encontrados en respuesta HTTP');
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

HTTP_BUILD=$(echo "$SERVER_RESPONSE" | grep "BUILD_TIMESTAMP en respuesta HTTP" | cut -d: -f2 | tr -d ' ')
HTTP_SUPABASE=$(echo "$SERVER_RESPONSE" | grep "supabase-client.js versión en respuesta HTTP" | cut -d: -f2 | tr -d ' ')

if [ ! -z "$HTTP_BUILD" ] && [ "$HTTP_BUILD" = "$BUILD_TS" ]; then
    echo "✅ Dashboard actualizado correctamente"
    echo ""
    echo "📊 Información:"
    echo "   - BUILD_TIMESTAMP: $HTTP_BUILD"
    echo "   - Contenedor: $CONTAINER_ID"
    echo "   - Servicio NO reiniciado (archivo actualizado en contenedor existente)"
    echo ""
    echo "🌐 Prueba el dashboard:"
    echo "   https://dashboard.checkin24hs.com"
    echo ""
    echo "   ⚠️ IMPORTANTE:"
    echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
    echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
    echo "   3. Si aún ves versión antigua, el servidor puede estar usando caché en memoria"
    echo "   4. En ese caso, necesitarás reiniciar el servicio (pero esto creará un nuevo contenedor)"
else
    if [ ! -z "$HTTP_BUILD" ]; then
        echo "⚠️ El servidor está sirviendo BUILD_TIMESTAMP: $HTTP_BUILD"
        echo "   Esperado: $BUILD_TS"
        echo ""
        echo "   El servidor puede estar usando caché en memoria"
        echo "   Necesitas reiniciar el servicio, pero esto creará un nuevo contenedor"
        echo ""
        echo "   SOLUCIÓN TEMPORAL:"
        echo "   docker service update --force $DASHBOARD_SERVICE"
        echo "   Luego ejecuta: ACTUALIZAR_DESPUES_REINICIO.sh"
    else
        echo "❌ El servidor no está sirviendo BUILD_TIMESTAMP"
    fi
    
    if [ ! -z "$HTTP_SUPABASE" ] && [ "$HTTP_SUPABASE" = "3.1.0" ]; then
        echo ""
        echo "⚠️ PROBLEMA: El servidor está sirviendo supabase-client.js v3.1.0 (antigua)"
        echo "   Esto confirma que está sirviendo una versión antigua del dashboard.html"
    fi
fi

echo ""
echo "📝 NOTA IMPORTANTE:"
echo "   Este script actualiza el archivo SIN reiniciar el servicio."
echo "   Si el servidor está usando caché en memoria, necesitarás reiniciar."
echo "   Pero al reiniciar, Docker Swarm creará un nuevo contenedor desde la imagen antigua."
echo "   La solución permanente es hacer un 'Build without cache' en EasyPanel."
echo ""
