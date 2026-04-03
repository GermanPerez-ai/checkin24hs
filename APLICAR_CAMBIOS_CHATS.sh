#!/bin/bash

echo "🔧 Aplicando cambios de filtrado de chats..."

cd /root/checkin24hs

# Encontrar contenedor del dashboard
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

echo "📦 Contenedor encontrado: $CONTAINER"

# Copiar archivo
echo "📋 Copiando dashboard.html al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

# Verificar que se copió correctamente
echo "🔍 Verificando que el archivo tiene los cambios..."
docker exec "$CONTAINER" grep -q "🚫 Chat spam excluido" /app/dashboard.html
if [ $? -eq 0 ]; then
    echo "✅ Archivo tiene los cambios de filtrado"
else
    echo "❌ El archivo NO tiene los cambios. Verificando contenido..."
    docker exec "$CONTAINER" grep -c "Chat spam excluido" /app/dashboard.html || echo "No se encontró el código de filtrado"
fi

# Reiniciar proceso Node.js
echo "🔄 Reiniciando proceso Node.js..."
docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || true

# Esperar un momento
sleep 2

# Verificar que el proceso se reinició
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null; then
    echo "✅ Proceso Node.js está corriendo"
else
    echo "⚠️ Proceso Node.js no está corriendo, puede que se reinicie automáticamente"
fi

echo ""
echo "✅ Cambios aplicados"
echo ""
echo "📝 Próximos pasos:"
echo "1. Recarga la página del dashboard (Ctrl+Shift+R o Cmd+Shift+R)"
echo "2. Abre la consola del navegador (F12)"
echo "3. Ve a la sección 'Chats'"
echo "4. Deberías ver logs como:"
echo "   - 🔍 Primeros 3 chats antes del filtrado"
echo "   - 🚫 Chat spam excluido: ..."
echo "   - 🔍 Chats filtrados: X -> Y"
echo ""
echo "Si no ves estos logs, el archivo puede estar en caché. Prueba:"
echo "- Hard refresh: Ctrl+Shift+R (Windows/Linux) o Cmd+Shift+R (Mac)"
echo "- Limpiar caché del navegador"




