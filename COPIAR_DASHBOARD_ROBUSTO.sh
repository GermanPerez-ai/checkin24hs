#!/bin/bash
# Script robusto para copiar dashboard.html sin corrupción

echo "=========================================="
echo "🔄 Copiando dashboard.html (Método Robusto)"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Crear directorio temporal
TEMP_DIR="/tmp/dashboard_robust_$$"
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

# Verificar integridad
if [ "$FILE_SIZE" -lt 1000000 ]; then
    echo "❌ El archivo es demasiado pequeño (puede estar corrupto)"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verificar que tiene BUILD_TIMESTAMP
if ! grep -q "BUILD_TIMESTAMP" dashboard.html; then
    echo "❌ El archivo descargado NO tiene BUILD_TIMESTAMP"
    echo "   Verificando primeras líneas..."
    head -20 dashboard.html
    rm -rf "$TEMP_DIR"
    exit 1
fi

BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
echo "✅ BUILD_TIMESTAMP encontrado: $BUILD_TS"

echo ""

# Hacer backup
echo "2️⃣ Haciendo backup del archivo actual..."
docker exec "$CONTAINER_ID" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"

echo ""

# Método 1: Copiar directamente
echo "3️⃣ Copiando archivo al contenedor (método directo)..."
docker cp dashboard.html "$CONTAINER_ID:/app/dashboard.html"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar con método directo"
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
    DIFF=$((FILE_SIZE - NEW_SIZE))
    echo "   ⚠️ Diferencia: $DIFF bytes"
    
    if [ "$DIFF" -gt 100000 ]; then
        echo "   ❌ Diferencia demasiado grande, el archivo puede estar corrupto"
        echo ""
        echo "   Intentando método alternativo..."
        
        # Método alternativo: copiar vía tar
        echo "5️⃣ Intentando método alternativo (tar)..."
        cd "$TEMP_DIR"
        tar cf dashboard.tar dashboard.html
        docker cp dashboard.tar "$CONTAINER_ID:/tmp/"
        docker exec "$CONTAINER_ID" tar xf /tmp/dashboard.tar -C /app/
        docker exec "$CONTAINER_ID" rm /tmp/dashboard.tar
        
        # Verificar de nuevo
        sleep 2
        NEW_SIZE2=$(docker exec "$CONTAINER_ID" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z /app/dashboard.html 2>/dev/null)
        echo "   Tamaño después de tar: $NEW_SIZE2 bytes"
        
        if [ "$NEW_SIZE2" = "$FILE_SIZE" ]; then
            echo "   ✅ Método tar funcionó"
        else
            echo "   ❌ Método tar tampoco funcionó"
        fi
    fi
else
    echo "   ✅ Los tamaños coinciden"
fi

echo ""

# Verificar BUILD_TIMESTAMP en el contenedor
echo "5️⃣ Verificando BUILD_TIMESTAMP en el contenedor..."
NEW_BUILD_TS=$(docker exec "$CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1)

if [ ! -z "$NEW_BUILD_TS" ]; then
    echo "✅ BUILD_TIMESTAMP encontrado:"
    echo "   $NEW_BUILD_TS"
    
    # Extraer el valor
    BUILD_VALUE=$(echo "$NEW_BUILD_TS" | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"")
    if [ ! -z "$BUILD_VALUE" ]; then
        echo "   Valor: $BUILD_VALUE"
    fi
else
    echo "❌ BUILD_TIMESTAMP NO encontrado en el contenedor"
    echo ""
    echo "   Verificando primeras líneas del archivo en contenedor..."
    docker exec "$CONTAINER_ID" head -20 /app/dashboard.html | head -5
fi

echo ""

# Verificar permisos
echo "6️⃣ Verificando permisos..."
docker exec "$CONTAINER_ID" chmod 644 /app/dashboard.html 2>/dev/null
PERMISSIONS=$(docker exec "$CONTAINER_ID" ls -l /app/dashboard.html 2>/dev/null | awk '{print $1, $3, $4}')
echo "   Permisos: $PERMISSIONS"

echo ""

# Verificar servidor
echo "7️⃣ Verificando que el servidor responde..."
sleep 3
SERVER_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    console.log('Status:', res.statusCode);
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Servidor responde correctamente"
else
    echo "⚠️ El servidor puede necesitar reinicio"
fi

echo ""

# Limpiar
echo "8️⃣ Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ ! -z "$NEW_BUILD_TS" ]; then
    echo "✅ Dashboard actualizado correctamente"
    echo ""
    echo "🌐 Prueba el dashboard:"
    echo "   https://dashboard.checkin24hs.com"
    echo ""
    echo "   ⚠️ IMPORTANTE:"
    echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
    echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
    echo "   3. Verifica que los caracteres especiales se muestren correctamente"
else
    echo "⚠️ La actualización puede no estar completa"
    echo ""
    echo "   El archivo se copió pero BUILD_TIMESTAMP no se detecta"
    echo "   Esto puede ser un problema de codificación o el archivo está corrupto"
    echo ""
    echo "   Prueba verificar manualmente:"
    echo "   docker exec $CONTAINER_ID head -20 /app/dashboard.html"
fi

echo ""
