#!/bin/bash
# Script para verificar que la corrección se aplicó correctamente

echo "=========================================="
echo "VERIFICAR CORRECCIÓN FINAL"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Verificar función completa (primeras 15 líneas)
echo "=== FUNCIÓN obtenerOcrearChatId (primeras 15 líneas) ==="
echo ""
docker exec $CONTAINER_ID grep -A 15 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | head -18
echo ""

# Verificar específicamente la línea del comentario
echo "=== VERIFICAR COMENTARIO DE PRIORIDAD ==="
echo ""
COMENTARIO=$(docker exec $CONTAINER_ID sed -n '708p' /app/whatsapp-server-baileys.js)
echo "Línea 708: $COMENTARIO"
echo ""

if echo "$COMENTARIO" | grep -qi "whatsapp_chats"; then
    echo "✅ CORRECCIÓN APLICADA CORRECTAMENTE"
    echo "   La función ahora prioriza whatsapp_chats"
else
    echo "❌ CORRECCIÓN NO APLICADA"
    echo "   La función aún prioriza whatsapp_conversations"
fi
echo ""

# Verificar que el contenedor está corriendo
echo "=== ESTADO DEL CONTENEDOR ==="
echo ""
docker ps | grep $CONTAINER_ID
echo ""

# Ver logs recientes
echo "=== LOGS RECIENTES ==="
echo ""
docker logs $CONTAINER_ID --tail 10
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
if echo "$COMENTARIO" | grep -qi "whatsapp_chats"; then
    echo "✅ Todo listo. Ahora puedes:"
    echo "1. Enviar un mensaje de prueba a Flor por WhatsApp"
    echo "2. Verificar que aparezca en la sección Chat del dashboard"
    echo "3. Ver logs: docker logs $CONTAINER_ID -f"
else
    echo "⚠️ Necesitas subir el archivo corregido nuevamente desde tu máquina local"
fi
echo ""
