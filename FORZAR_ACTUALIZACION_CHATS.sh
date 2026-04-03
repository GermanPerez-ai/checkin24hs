#!/bin/bash

echo "🔧 Forzando actualización de filtrado de chats..."

cd /root/checkin24hs

# Encontrar contenedor del dashboard
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

echo "📦 Contenedor encontrado: $CONTAINER"

# Verificar que el archivo local tiene los cambios
echo "🔍 Verificando archivo local..."
if grep -q "🚫 Chat spam excluido" deploy/dashboard.html; then
    echo "✅ Archivo local tiene los cambios"
else
    echo "❌ El archivo local NO tiene los cambios. Necesitas subirlo primero."
    exit 1
fi

# Copiar archivo
echo "📋 Copiando dashboard.html al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

# Verificar que se copió correctamente
echo "🔍 Verificando que el archivo en el contenedor tiene los cambios..."
docker exec "$CONTAINER" grep -q "🚫 Chat spam excluido" /app/dashboard.html
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente al contenedor"
    
    # Mostrar cuántas veces aparece el código de filtrado
    COUNT=$(docker exec "$CONTAINER" grep -c "Chat spam excluido" /app/dashboard.html)
    echo "📊 Código de filtrado encontrado $COUNT veces en el archivo"
else
    echo "❌ ERROR: El archivo en el contenedor NO tiene los cambios"
    echo "🔍 Verificando contenido del archivo en el contenedor..."
    docker exec "$CONTAINER" head -n 24300 /app/dashboard.html | tail -n 20
    exit 1
fi

# Reiniciar proceso Node.js de forma más agresiva
echo "🔄 Reiniciando proceso Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 3

# Verificar que el proceso se reinició
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null; then
    echo "✅ Proceso Node.js está corriendo"
else
    echo "⚠️ Proceso Node.js no está corriendo, puede que se reinicie automáticamente"
    sleep 2
    if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null; then
        echo "✅ Proceso Node.js se reinició correctamente"
    else
        echo "❌ ERROR: Proceso Node.js no se reinició"
    fi
fi

# Verificar timestamp del archivo
echo "📅 Timestamp del archivo en el contenedor:"
docker exec "$CONTAINER" ls -lh /app/dashboard.html | awk '{print $6, $7, $8}'

echo ""
echo "✅ Cambios aplicados y verificados"
echo ""
echo "📝 IMPORTANTE - Próximos pasos:"
echo "1. Abre las herramientas de desarrollador (F12)"
echo "2. Ve a la pestaña 'Network'"
echo "3. Marca la casilla 'Disable cache'"
echo "4. Ve a la pestaña 'Console'"
echo "5. Recarga la página con Ctrl+Shift+R (o Cmd+Shift+R en Mac)"
echo "6. Ve a la sección 'Chats'"
echo "7. Deberías ver estos logs:"
echo "   - 🔍 Primeros 3 chats antes del filtrado"
echo "   - 🚫 Chat spam excluido: ... (para cada chat de spam)"
echo "   - 🔍 Chats filtrados: 50 -> X"
echo ""
echo "Si NO ves estos logs después de hacer hard refresh, el problema es caché del navegador."




