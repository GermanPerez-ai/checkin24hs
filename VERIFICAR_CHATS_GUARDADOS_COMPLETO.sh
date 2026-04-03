#!/bin/bash
# Verificar si los chats se están guardando correctamente

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR CHATS GUARDADOS"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver logs de creación/actualización de chats
echo "1. Logs de creación/actualización de chats..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -E "Nuevo chat creado|Chat existente encontrado|Error creando chat|Chat actualizado|PROBLEMA.*cuota" | tail -10
echo ""

# 2. Ver logs de guardado de mensajes
echo "2. Logs de guardado de mensajes..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -E "Mensaje guardado|guardarMensaje|whatsapp_messages" | tail -10
echo ""

# 3. Ver logs de interacciones de Flor
echo "3. Logs de interacciones de Flor..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -E "Flor respondió|guardarFlorInteraction|flor_interactions" | tail -10
echo ""

# 4. Verificar código de logging mejorado
echo "4. Verificando código de logging mejorado..."
echo ""
docker exec $CONTAINER_ID grep -A 2 "Evento messages.upsert recibido" /app/whatsapp-server-baileys.js | head -3
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Si no ves 'Nuevo chat creado' o 'Chat existente encontrado',"
echo "   puede ser que los chats no se estén guardando en Supabase."
echo ""
echo "📋 Verifica en Supabase SQL Editor:"
echo "   SELECT COUNT(*) as total_chats FROM whatsapp_chats;"
echo "   SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;"
echo ""
