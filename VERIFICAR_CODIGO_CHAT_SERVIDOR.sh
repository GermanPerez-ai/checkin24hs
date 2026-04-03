#!/bin/bash
# Script para verificar el código de guardado de chats en el servidor

echo "=========================================="
echo "VERIFICAR CÓDIGO DE GUARDADO DE CHAT"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar función obtenerOcrearChatId
echo "=== FUNCIÓN obtenerOcrearChatId ==="
echo ""
echo "Buscando función:"
docker exec $CONTAINER_ID grep -n "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js
echo ""

# 2. Verificar que prioriza whatsapp_chats
echo "=== VERIFICAR PRIORIDAD whatsapp_chats ==="
echo ""
echo "Líneas relevantes de la función:"
docker exec $CONTAINER_ID sed -n '/async function obtenerOcrearChatId/,/^}$/p' /app/whatsapp-server-baileys.js | grep -A 5 -B 2 "whatsapp_chats" | head -20
echo ""

# 3. Verificar si dice "PRIMERO: Intentar con whatsapp_chats"
echo "=== VERIFICAR COMENTARIO DE PRIORIDAD ==="
echo ""
PRIORIDAD=$(docker exec $CONTAINER_ID grep -A 3 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -i "PRIMERO\|whatsapp_chats")
if [ -n "$PRIORIDAD" ]; then
    echo "✅ Encontrado comentario de prioridad:"
    echo "$PRIORIDAD"
else
    echo "⚠️ No se encontró comentario de prioridad"
fi
echo ""

# 4. Verificar logs recientes de guardado
echo "=== LOGS DE GUARDADO (últimas 50 líneas) ==="
echo ""
docker logs $CONTAINER_ID --tail 50 | grep -iE "Mensaje guardado|Chat actualizado|Nuevo chat creado|obtenerOcrearChatId|Error guardando"
echo ""

# 5. Verificar si hay errores
echo "=== ERRORES RECIENTES ==="
echo ""
ERRORES=$(docker logs $CONTAINER_ID --tail 100 | grep -iE "Error guardando|No se pudo obtener/crear chat_id|Error actualizando whatsapp_chats|Invalid API key")
if [ -n "$ERRORES" ]; then
    echo "❌ Errores encontrados:"
    echo "$ERRORES"
else
    echo "✅ No se encontraron errores recientes"
fi
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
