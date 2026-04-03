#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO Y CORRIGIENDO from_me ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontro contenedor de dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Verificar archivo local
echo "1. Verificando archivo local..."
if grep -q "is_from_me" deploy/dashboard.html; then
    echo "   ✅ Archivo local tiene 'is_from_me'"
else
    echo "   ❌ Archivo local NO tiene 'is_from_me'"
    exit 1
fi

# Verificar si tiene from_me (incorrecto)
if grep -q "\.select.*from_me" deploy/dashboard.html; then
    echo "   ⚠️ Archivo local tiene 'from_me' (incorrecto)"
    echo "   Corrigiendo..."
    sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" deploy/dashboard.html
    sed -i "s/\.select(\"id, chat_id, body, created_at, from_me\")/\.select(\"id, chat_id, body, created_at, is_from_me\")/g" deploy/dashboard.html
    echo "   ✅ Corregido"
fi

echo ""

# Verificar archivo en contenedor ANTES de copiar
echo "2. Verificando archivo en contenedor (ANTES)..."
if docker exec "$CONTAINER" grep -q "\.select.*from_me" /app/dashboard.html 2>/dev/null; then
    echo "   ⚠️ Contenedor tiene 'from_me' (incorrecto)"
    NEEDS_UPDATE=true
else
    echo "   ✅ Contenedor tiene 'is_from_me' (correcto)"
    NEEDS_UPDATE=false
fi

echo ""

# Copiar archivo
echo "3. Copiando archivo al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado"
else
    echo "   ❌ Error al copiar archivo"
    exit 1
fi

echo ""

# Verificar archivo en contenedor DESPUÉS de copiar
echo "4. Verificando archivo en contenedor (DESPUÉS)..."
if docker exec "$CONTAINER" grep -q "\.select.*is_from_me" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ Contenedor tiene 'is_from_me' (correcto)"
else
    echo "   ❌ Contenedor NO tiene 'is_from_me'"
    exit 1
fi

# Verificar que NO tiene from_me (incorrecto)
if docker exec "$CONTAINER" grep -q "\.select.*from_me" /app/dashboard.html 2>/dev/null; then
    echo "   ⚠️ Contenedor todavía tiene 'from_me' (incorrecto)"
    echo "   Corrigiendo directamente en el contenedor..."
    docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
    docker exec "$CONTAINER" sed -i "s/\.select(\"id, chat_id, body, created_at, from_me\")/\.select(\"id, chat_id, body, created_at, is_from_me\")/g" /app/dashboard.html
    echo "   ✅ Corregido en el contenedor"
fi

echo ""

# Reiniciar Node.js
echo "5. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 3

# Verificar que Node.js está corriendo
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null; then
    echo "   ✅ Node.js reiniciado correctamente"
else
    echo "   ⚠️ Node.js no está corriendo, puede que necesite iniciarse manualmente"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "Instrucciones:"
echo "1. Abre el dashboard en modo incógnito o limpia el caché del navegador"
echo "2. Presiona Ctrl+Shift+R (o Cmd+Shift+R en Mac) para forzar recarga"
echo "3. Ve a la sección de Chats"
echo "4. Selecciona un chat"
echo "5. Ahora deberías ver los mensajes correctamente"
echo ""
echo "El error 'column whatsapp_messages.from_me does not exist' debería estar resuelto."


