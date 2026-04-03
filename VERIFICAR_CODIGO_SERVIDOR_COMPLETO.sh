#!/bin/bash
# Verificar el código completo de actualización de chats en el servidor

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Ver el código exacto de actualización de chats (líneas 857-880)
echo "=== CÓDIGO ACTUAL (líneas 857-880) ==="
echo ""
docker exec $CONTAINER_ID sed -n '857,880p' /app/whatsapp-server-baileys.js
echo ""

# Verificar si tiene dataChat
echo "=== VERIFICAR SI TIENE dataChat ==="
echo ""
docker exec $CONTAINER_ID grep -n "dataChat" /app/whatsapp-server-baileys.js | head -5
echo ""

# Verificar si tiene .select() en whatsapp_chats
echo "=== VERIFICAR .select() EN whatsapp_chats ==="
echo ""
docker exec $CONTAINER_ID grep -B 3 -A 3 "whatsapp_chats.*\.select()" /app/whatsapp-server-baileys.js
echo ""
