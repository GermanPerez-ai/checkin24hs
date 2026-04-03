#!/bin/bash
# Verificar el código actual en el servidor

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Ver el código actual de actualización de chats
echo "=== CÓDIGO ACTUAL DE ACTUALIZACIÓN DE CHATS ==="
echo ""
docker exec $CONTAINER_ID sed -n '857,875p' /app/whatsapp-server-baileys.js
echo ""

# Verificar si tiene .select() en la actualización de chats
echo "=== VERIFICAR .select() EN ACTUALIZACIÓN DE CHATS ==="
echo ""
docker exec $CONTAINER_ID grep -B 5 -A 10 "from('whatsapp_chats')" /app/whatsapp-server-baileys.js | grep -A 15 "\.update(" | head -20
echo ""
