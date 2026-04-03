#!/bin/bash
# Verificar que el logging mejorado se aplicó correctamente

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR LOGGING MEJORADO DE CHATS"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# Verificar que el código tiene el logging mejorado
echo "1. Verificando código de creación de chats..."
echo ""
docker exec $CONTAINER_ID grep -A 5 "Error creando chat en whatsapp_chats" /app/whatsapp-server-baileys.js | head -10
echo ""

# Verificar que tiene el mensaje de cuota
echo "2. Verificando detección de cuota..."
echo ""
docker exec $CONTAINER_ID grep -A 2 "PROBLEMA.*cuota" /app/whatsapp-server-baileys.js | head -5
echo ""

# Verificar que tiene el mensaje de bloqueo silencioso
echo "3. Verificando detección de bloqueo silencioso..."
echo ""
docker exec $CONTAINER_ID grep -A 2 "Creación de chat no devolvió datos" /app/whatsapp-server-baileys.js | head -5
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "✅ Si ves los mensajes de error detallados arriba, el código está correcto."
echo ""
echo "📋 Próximos pasos:"
echo "   1. Envía un mensaje de WhatsApp al bot"
echo "   2. Ejecuta: docker logs $CONTAINER_ID --tail 100 | grep -E 'Error creando chat|Nuevo chat creado|PROBLEMA.*cuota|Creación de chat no devolvió'"
echo ""
