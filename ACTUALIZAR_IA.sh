#!/bin/bash
cd /root/checkin24hs

echo "🔄 Actualizando dashboard con campos de IA..."

# Verificar si el archivo tiene los campos
if [ -f "dashboard.html" ] && grep -q "ai-temperature" dashboard.html 2>/dev/null; then
    echo "✅ dashboard.html tiene los campos nuevos"
    # Copiar a deploy
    cp dashboard.html deploy/dashboard.html
    echo "✅ Copiado a deploy/dashboard.html"
elif [ -f "deploy/dashboard.html" ] && grep -q "ai-temperature" deploy/dashboard.html 2>/dev/null; then
    echo "✅ deploy/dashboard.html tiene los campos nuevos"
else
    echo "❌ ERROR: El archivo NO tiene los campos nuevos"
    echo "📥 Necesitas subir el archivo desde tu máquina Windows:"
    echo "   scp dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

# Encontrar contenedor
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    docker ps
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"

# Copiar al contenedor
echo "📤 Copiando archivo al contenedor..."
docker cp deploy/dashboard.html ${CONTAINER_ID}:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi

# Verificar
if docker exec ${CONTAINER_ID} grep -q "ai-temperature" /app/dashboard.html 2>/dev/null; then
    echo "✅ Campos copiados correctamente al contenedor"
else
    echo "❌ Error: Los campos NO se copiaron al contenedor"
    exit 1
fi

# Reiniciar
echo "🔄 Reiniciando contenedor..."
docker restart ${CONTAINER_ID}
sleep 10

# Verificar que está corriendo
if docker ps | grep -q "$CONTAINER_ID"; then
    echo "✅ Contenedor está corriendo"
else
    echo "⚠️ El contenedor no está corriendo, verifica los logs:"
    echo "   docker logs $CONTAINER_ID"
fi

echo ""
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 IMPORTANTE:"
echo "1. Limpia la caché del navegador (Ctrl+Shift+R)"
echo "2. Recarga la página del dashboard"
echo "3. Ve a: Flor IA → Pestaña '🤖 IA'"
echo "4. Marca el checkbox 'Habilitar respuestas con IA'"
echo "5. Deberías ver todos los campos: Proveedor, API Key, Modelo, Temperature, Max Tokens"
echo "=========================================="








