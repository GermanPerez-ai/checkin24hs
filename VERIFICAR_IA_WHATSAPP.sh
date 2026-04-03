#!/bin/bash
# Script para verificar por qué la IA no responde en WhatsApp

echo "=========================================="
echo "VERIFICAR IA DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Buscar contenedor de WhatsApp
echo "1. Buscando contenedor de WhatsApp..."
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"
echo ""

# 2. Verificar variables de entorno relacionadas con Gemini
echo "2. Verificando variables de entorno (GEMINI_API_KEY, FLOR_ENABLED, etc.)..."
docker exec $CONTAINER_ID env | grep -E "(GEMINI|FLOR|AUTO_REPLY)" | grep -v "PASSWORD\|SECRET"
echo ""

# 3. Ver logs recientes del servidor
echo "3. Últimos logs del servidor (últimas 50 líneas):"
docker logs $CONTAINER_ID --tail 50
echo ""

# 4. Buscar errores específicos relacionados con Gemini/IA
echo "4. Buscando errores relacionados con Gemini/IA:"
docker logs $CONTAINER_ID --tail 100 | grep -iE "(gemini|flor|ia|error|❌|⚠️)" | tail -20
echo ""

# 5. Verificar si hay mensajes de "GEMINI_API_KEY no configurada"
echo "5. Verificando si GEMINI_API_KEY está configurada:"
docker logs $CONTAINER_ID --tail 200 | grep -i "GEMINI_API_KEY\|API key\|no configurada" | tail -10
echo ""

# 6. Verificar si procesarConFlor está siendo llamado
echo "6. Verificando si procesarConFlor está siendo llamado:"
docker logs $CONTAINER_ID --tail 200 | grep -i "procesarConFlor\|Flor respondió\|Flor IA" | tail -10
echo ""

# 7. Verificar configuración en el archivo
echo "7. Verificando configuración en el archivo del servidor:"
docker exec $CONTAINER_ID grep -E "GEMINI_API_KEY|FLOR_ENABLED|USE_GEMINI_AI" /app/whatsapp-server-baileys.js | head -5
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Revisa los resultados arriba para identificar el problema."
echo ""
