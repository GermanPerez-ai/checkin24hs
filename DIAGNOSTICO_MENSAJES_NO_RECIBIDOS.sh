#!/bin/bash
# Diagnóstico completo: mensajes no se están recibiendo

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "DIAGNÓSTICO: MENSAJES NO RECIBIDOS"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar que el handler está registrado
echo "1. Verificando handler de mensajes..."
echo ""
docker exec $CONTAINER_ID grep -A 3 "sock.ev.on('messages.upsert'" /app/whatsapp-server-baileys.js | head -5
echo ""

# 2. Verificar que el logging está aplicado
echo "2. Verificando logging aplicado..."
echo ""
docker exec $CONTAINER_ID grep -A 2 "Evento messages.upsert recibido" /app/whatsapp-server-baileys.js | head -3
echo ""

# 3. Ver logs completos recientes (sin filtros)
echo "3. Logs completos (últimas 50 líneas)..."
echo ""
docker logs $CONTAINER_ID --tail 50
echo ""

# 4. Ver si hay errores de JavaScript
echo "4. Buscando errores de JavaScript..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -iE "error|exception|failed|undefined|null" | tail -10
echo ""

# 5. Verificar estado de conexión
echo "5. Estado de conexión..."
echo ""
docker logs $CONTAINER_ID --tail 20 | grep -E "conectado|connection|Estado:" | tail -5
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Si el handler está registrado pero no ves mensajes:"
echo "   1. Verifica que realmente enviaste un mensaje al bot"
echo "   2. Verifica que el mensaje aparece como 'enviado' o 'entregado' en tu teléfono"
echo "   3. Puede haber un problema con Baileys que no está disparando el evento"
echo ""
