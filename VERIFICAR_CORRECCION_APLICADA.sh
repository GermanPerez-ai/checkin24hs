#!/bin/bash
# Script para verificar que la corrección de chat se aplicó correctamente

echo "=========================================="
echo "VERIFICAR CORRECCIÓN DE CHAT APLICADA"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar que la función prioriza whatsapp_chats
echo "=== VERIFICAR PRIORIDAD whatsapp_chats ==="
echo ""
PRIORIDAD=$(docker exec $CONTAINER_ID grep -A 3 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -i "PRIMERO.*whatsapp_chats")
if [ -n "$PRIORIDAD" ]; then
    echo "✅ Corrección aplicada correctamente:"
    echo "$PRIORIDAD"
else
    echo "❌ No se encontró la corrección. La función aún prioriza whatsapp_conversations."
    echo ""
    echo "Código actual:"
    docker exec $CONTAINER_ID grep -A 5 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | head -10
fi
echo ""

# 2. Verificar que el contenedor está corriendo
echo "=== ESTADO DEL CONTENEDOR ==="
echo ""
docker ps | grep $CONTAINER_ID
echo ""

# 3. Verificar logs recientes
echo "=== LOGS RECIENTES (últimas 20 líneas) ==="
echo ""
docker logs $CONTAINER_ID --tail 20
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Si la corrección se aplicó correctamente:"
echo "1. Envía un mensaje de prueba a Flor por WhatsApp"
echo "2. Verifica que aparezca en la sección Chat del dashboard"
echo "3. Verifica los logs: docker logs $CONTAINER_ID -f"
echo ""
