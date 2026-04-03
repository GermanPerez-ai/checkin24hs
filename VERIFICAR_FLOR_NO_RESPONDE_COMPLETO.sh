#!/bin/bash
# Verificar por qué Flor IA no responde

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR FLOR IA NO RESPONDE"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar si se están recibiendo mensajes
echo "1. Mensajes recibidos recientemente..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -E "📱 Mensaje recibido|messages.upsert" | tail -10
echo ""

# 2. Verificar si Flor está intentando responder
echo "2. Intentos de respuesta de Flor IA..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -E "Flor respondió|procesarConFlor|Procesando.*mensaje|Gemini|gemini" | tail -20
echo ""

# 3. Ver errores relacionados con Flor
echo "3. Errores relacionados con Flor IA..."
echo ""
docker logs $CONTAINER_ID --tail 100 | grep -iE "error.*flor|error.*gemini|error.*ia|error.*ai" | tail -10
echo ""

# 4. Ver logs completos recientes
echo "4. Logs completos (últimas 30 líneas)..."
echo ""
docker logs $CONTAINER_ID --tail 30
echo ""

# 5. Verificar variables de entorno
echo "5. Variables de entorno de Flor..."
echo ""
docker exec $CONTAINER_ID env | grep -E "FLOR_ENABLED|AUTO_REPLY|GEMINI_API_KEY" || echo "⚠️ No se encontraron variables FLOR_ENABLED o AUTO_REPLY"
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
