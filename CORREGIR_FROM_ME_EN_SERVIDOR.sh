#!/bin/bash
cd /root/checkin24hs

echo "=== CORRIGIENDO from_me EN EL SERVIDOR ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontro contenedor de dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Verificar archivo local primero
echo "1. Verificando archivo local..."
if [ -f "deploy/dashboard.html" ]; then
    echo "   ✅ Archivo local existe"
    # Copiar archivo local al contenedor
    echo "   📦 Copiando archivo local al contenedor..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    if [ $? -eq 0 ]; then
        echo "   ✅ Archivo copiado"
    else
        echo "   ❌ Error al copiar archivo"
        exit 1
    fi
else
    echo "   ⚠️ Archivo local no existe, corrigiendo directamente en el contenedor"
fi

echo ""

# Corregir directamente en el contenedor (por si acaso)
echo "2. Corrigiendo 'from_me' a 'is_from_me' en el contenedor..."
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Verificar que se corrigió
echo "3. Verificando corrección..."
if docker exec "$CONTAINER" grep -q "\.select.*is_from_me" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ Archivo tiene 'is_from_me'"
else
    echo "   ❌ Archivo NO tiene 'is_from_me'"
    exit 1
fi

# Verificar que NO tiene from_me (incorrecto)
if docker exec "$CONTAINER" grep -q "\.select.*from_me" /app/dashboard.html 2>/dev/null; then
    echo "   ⚠️ Archivo todavía tiene 'from_me' (incorrecto)"
    echo "   🔧 Intentando corrección adicional..."
    docker exec "$CONTAINER" sed -i 's/from_me/is_from_me/g' /app/dashboard.html
    echo "   ✅ Corrección adicional aplicada"
else
    echo "   ✅ Archivo NO tiene 'from_me' (correcto)"
fi

echo ""

# Reiniciar Node.js
echo "4. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 5

# Verificar que Node.js está corriendo
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Node.js reiniciado correctamente"
else
    echo "   ⚠️ Node.js no está corriendo, esperando más tiempo..."
    sleep 5
    if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Node.js está corriendo ahora"
    else
        echo "   ⚠️ Node.js puede necesitar iniciarse manualmente"
    fi
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "Instrucciones:"
echo "1. Abre el dashboard en modo incógnito o presiona Ctrl+Shift+R para forzar recarga"
echo "2. Ve a la sección de Chats"
echo "3. Selecciona un chat"
echo "4. Ahora deberías ver los mensajes correctamente"
echo ""
echo "El error 'column whatsapp_messages.from_me does not exist' debería estar resuelto."


