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

# 1. Verificar variables de entorno
echo "1. Verificando variables de entorno..."
echo ""
docker exec $CONTAINER_ID env | grep -E "FLOR_ENABLED|AUTO_REPLY|GEMINI_API_KEY|FLOR_DELAY" | head -10
echo ""

# 2. Ver logs recientes de mensajes recibidos
echo "2. Últimos mensajes recibidos (últimos 2 minutos)..."
echo ""
docker logs $CONTAINER_ID --since 2m | grep -iE "mensaje recibido|message received|from:|📨" | tail -10
echo ""

# 3. Ver errores relacionados con Flor IA
echo "3. Errores relacionados con Flor IA..."
echo ""
docker logs $CONTAINER_ID --since 2m | grep -iE "flor|gemini|ia|ai|error.*gemini|error.*flor" | tail -20
echo ""

# 4. Ver si hay intentos de respuesta
echo "4. Intentos de respuesta de Flor IA..."
echo ""
docker logs $CONTAINER_ID --since 2m | grep -iE "respondiendo|responding|flor.*respond|enviando.*flor" | tail -10
echo ""

# 5. Ver logs completos recientes
echo "5. Logs completos (últimas 30 líneas)..."
echo ""
docker logs $CONTAINER_ID --tail 30
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Revisa los logs arriba para identificar el problema."
echo ""
