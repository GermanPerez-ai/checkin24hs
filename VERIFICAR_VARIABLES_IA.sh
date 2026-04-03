#!/bin/bash
# Script para verificar todas las variables de entorno relacionadas con la IA

echo "=========================================="
echo "VERIFICAR VARIABLES DE ENTORNO - IA"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Verificar TODAS las variables relacionadas con IA
echo "=== VARIABLES DE ENTORNO ==="
echo ""
echo "GEMINI_API_KEY:"
docker exec $CONTAINER_ID env | grep "^GEMINI_API_KEY=" | sed 's/\(.\{20\}\).*/\1.../'
echo ""

echo "FLOR_ENABLED:"
docker exec $CONTAINER_ID env | grep "^FLOR_ENABLED=" || echo "⚠️ FLOR_ENABLED NO ESTÁ CONFIGURADA (usará valor por defecto)"
echo ""

echo "AUTO_REPLY:"
docker exec $CONTAINER_ID env | grep "^AUTO_REPLY=" || echo "⚠️ AUTO_REPLY NO ESTÁ CONFIGURADA (usará valor por defecto)"
echo ""

echo "FLOR_DELAY_MS:"
docker exec $CONTAINER_ID env | grep "^FLOR_DELAY_MS=" || echo "⚠️ FLOR_DELAY_MS NO ESTÁ CONFIGURADA (usará 5000ms por defecto)"
echo ""

echo "GEMINI_MODEL:"
docker exec $CONTAINER_ID env | grep "^GEMINI_MODEL=" || echo "⚠️ GEMINI_MODEL NO ESTÁ CONFIGURADA (usará gemini-2.5-flash por defecto)"
echo ""

# Verificar valores en el código
echo "=== VALORES EN EL CÓDIGO (hardcodeados) ==="
echo ""
docker exec $CONTAINER_ID grep -A 2 "AUTO_REPLY:" /app/whatsapp-server-baileys.js | head -3
docker exec $CONTAINER_ID grep -A 2 "FLOR_ENABLED:" /app/whatsapp-server-baileys.js | head -3
echo ""

# Verificar si hay mensajes siendo recibidos
echo "=== ÚLTIMOS MENSAJES RECIBIDOS ==="
echo ""
docker logs $CONTAINER_ID --tail 500 | grep -i "📱 Mensaje recibido\|mensaje recibido\|message received" | tail -10
echo ""

# Verificar si Flor está procesando
echo "=== PROCESAMIENTO DE FLOR ==="
echo ""
docker logs $CONTAINER_ID --tail 500 | grep -iE "procesando.*mensaje|Flor respondió|procesarConFlor" | tail -10
echo ""

echo "=========================================="
echo "DIAGNÓSTICO"
echo "=========================================="
echo ""

# Verificar si AUTO_REPLY está deshabilitado
AUTO_REPLY_ENV=$(docker exec $CONTAINER_ID env | grep "^AUTO_REPLY=" | cut -d'=' -f2)
if [ "$AUTO_REPLY_ENV" = "false" ] || [ "$AUTO_REPLY_ENV" = "0" ]; then
    echo "❌ PROBLEMA ENCONTRADO: AUTO_REPLY está deshabilitado en variables de entorno"
    echo "   Solución: Configurar AUTO_REPLY=true en EasyPanel"
    echo ""
fi

# Verificar si FLOR_ENABLED está deshabilitado
FLOR_ENABLED_ENV=$(docker exec $CONTAINER_ID env | grep "^FLOR_ENABLED=" | cut -d'=' -f2)
if [ "$FLOR_ENABLED_ENV" = "false" ] || [ "$FLOR_ENABLED_ENV" = "0" ]; then
    echo "❌ PROBLEMA ENCONTRADO: FLOR_ENABLED está deshabilitado en variables de entorno"
    echo "   Solución: Configurar FLOR_ENABLED=true en EasyPanel"
    echo ""
fi

# Verificar si GEMINI_API_KEY está vacía
GEMINI_KEY=$(docker exec $CONTAINER_ID env | grep "^GEMINI_API_KEY=" | cut -d'=' -f2)
if [ -z "$GEMINI_KEY" ]; then
    echo "❌ PROBLEMA ENCONTRADO: GEMINI_API_KEY está vacía"
    echo "   Solución: Configurar GEMINI_API_KEY en EasyPanel"
    echo ""
else
    echo "✅ GEMINI_API_KEY está configurada"
    echo ""
fi

echo "=========================================="
