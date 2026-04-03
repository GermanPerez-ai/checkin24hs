#!/bin/bash
# Verificar si el handler de mensajes está registrado correctamente

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR HANDLER DE MENSAJES"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar que el handler está en el código
echo "1. Verificando que el handler está registrado..."
echo ""
docker exec $CONTAINER_ID grep -A 2 "sock.ev.on('messages.upsert'" /app/whatsapp-server-baileys.js | head -5
echo ""

# 2. Verificar que el logging está aplicado
echo "2. Verificando logging aplicado..."
echo ""
docker exec $CONTAINER_ID grep -A 2 "Evento messages.upsert recibido" /app/whatsapp-server-baileys.js | head -5
echo ""

# 3. Ver logs completos recientes
echo "3. Logs completos (últimas 30 líneas)..."
echo ""
docker logs $CONTAINER_ID --tail 30
echo ""

# 4. Ver si hay errores
echo "4. Errores recientes..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -iE "error|❌|fail|exception" | tail -10
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Si el handler está registrado pero no ves mensajes, puede ser que:"
echo "   1. No se están recibiendo mensajes (WhatsApp no está escuchando)"
echo "   2. Los mensajes se están filtrando antes de llegar al handler"
echo "   3. Hay un error silencioso"
echo ""
