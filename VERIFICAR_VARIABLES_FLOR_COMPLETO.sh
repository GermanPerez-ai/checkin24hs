#!/bin/bash
# Verificar todas las variables relacionadas con Flor IA

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR VARIABLES FLOR IA"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# Ver TODAS las variables de entorno
echo "1. Todas las variables de entorno del contenedor:"
echo ""
docker exec $CONTAINER_ID env | sort
echo ""

# Verificar específicamente FLOR y AUTO_REPLY
echo "2. Variables específicas de Flor:"
echo ""
docker exec $CONTAINER_ID env | grep -iE "FLOR|AUTO_REPLY|GEMINI" || echo "⚠️ No se encontraron variables FLOR_ENABLED o AUTO_REPLY"
echo ""

# Ver cómo se están parseando en el código
echo "3. Verificando cómo se parsean en el código:"
echo ""
docker exec $CONTAINER_ID grep -A 5 "FLOR_ENABLED\|AUTO_REPLY" /app/whatsapp-server-baileys.js | head -20
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
