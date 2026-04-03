#!/bin/bash
# Script para aplicar corrección de variables de IA y verificar configuración

echo "=========================================="
echo "APLICAR CORRECCIÓN DE IA"
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

# 1. Verificar variables actuales
echo "=== PASO 1: VERIFICAR VARIABLES ACTUALES ==="
echo ""
echo "Variables de entorno relacionadas con IA:"
docker exec $CONTAINER_ID env | grep -E "(AUTO_REPLY|FLOR_ENABLED|GEMINI_API_KEY|FLOR_DELAY)" | grep -v "PASSWORD\|SECRET"
echo ""

# 2. Verificar si hay mensajes siendo recibidos
echo "=== PASO 2: VERIFICAR MENSAJES RECIBIDOS ==="
echo ""
MENSAJES=$(docker logs $CONTAINER_ID --tail 500 | grep -i "📱 Mensaje recibido" | wc -l)
echo "Mensajes recibidos en últimos logs: $MENSAJES"
if [ "$MENSAJES" -eq 0 ]; then
    echo "⚠️ No se encontraron mensajes recibidos en los logs recientes"
    echo "   Esto puede significar:"
    echo "   - No se han enviado mensajes de prueba"
    echo "   - Los mensajes no se están recibiendo"
    echo "   - AUTO_REPLY o FLOR_ENABLED están deshabilitados"
fi
echo ""

# 3. Verificar si Flor está procesando
echo "=== PASO 3: VERIFICAR PROCESAMIENTO DE FLOR ==="
echo ""
FLOR_PROCESANDO=$(docker logs $CONTAINER_ID --tail 500 | grep -iE "procesando.*mensaje|Flor respondió|procesarConFlor" | wc -l)
echo "Procesamientos de Flor en últimos logs: $FLOR_PROCESANDO"
if [ "$FLOR_PROCESANDO" -eq 0 ]; then
    echo "⚠️ No se encontraron procesamientos de Flor en los logs recientes"
fi
echo ""

# 4. Verificar valores en el código
echo "=== PASO 4: VERIFICAR CÓDIGO ==="
echo ""
echo "Valores hardcodeados en el código:"
docker exec $CONTAINER_ID grep -A 1 "AUTO_REPLY:" /app/whatsapp-server-baileys.js | head -2
docker exec $CONTAINER_ID grep -A 1 "FLOR_ENABLED:" /app/whatsapp-server-baileys.js | head -2
echo ""

# 5. Diagnóstico
echo "=== DIAGNÓSTICO ==="
echo ""

AUTO_REPLY_ENV=$(docker exec $CONTAINER_ID env | grep "^AUTO_REPLY=" | cut -d'=' -f2)
FLOR_ENABLED_ENV=$(docker exec $CONTAINER_ID env | grep "^FLOR_ENABLED=" | cut -d'=' -f2)
GEMINI_KEY=$(docker exec $CONTAINER_ID env | grep "^GEMINI_API_KEY=" | cut -d'=' -f2)

PROBLEMAS=0

if [ -n "$AUTO_REPLY_ENV" ] && [ "$AUTO_REPLY_ENV" != "true" ] && [ "$AUTO_REPLY_ENV" != "1" ]; then
    echo "❌ PROBLEMA: AUTO_REPLY=$AUTO_REPLY_ENV (debe ser 'true' o '1')"
    PROBLEMAS=$((PROBLEMAS + 1))
else
    echo "✅ AUTO_REPLY: OK"
fi

if [ -n "$FLOR_ENABLED_ENV" ] && [ "$FLOR_ENABLED_ENV" != "true" ] && [ "$FLOR_ENABLED_ENV" != "1" ]; then
    echo "❌ PROBLEMA: FLOR_ENABLED=$FLOR_ENABLED_ENV (debe ser 'true' o '1')"
    PROBLEMAS=$((PROBLEMAS + 1))
else
    echo "✅ FLOR_ENABLED: OK"
fi

if [ -z "$GEMINI_KEY" ]; then
    echo "❌ PROBLEMA: GEMINI_API_KEY está vacía"
    PROBLEMAS=$((PROBLEMAS + 1))
else
    echo "✅ GEMINI_API_KEY: Configurada"
fi

echo ""

if [ $PROBLEMAS -gt 0 ]; then
    echo "=========================================="
    echo "SOLUCIÓN"
    echo "=========================================="
    echo ""
    echo "Necesitas configurar las variables en EasyPanel:"
    echo ""
    echo "1. Accede a EasyPanel: http://72.61.58.240:3006"
    echo "2. Ve al servicio de WhatsApp"
    echo "3. Variables de entorno"
    echo "4. Verifica/Agrega:"
    echo "   - AUTO_REPLY=true"
    echo "   - FLOR_ENABLED=true"
    echo "   - GEMINI_API_KEY=tu_api_key (si está vacía)"
    echo "5. Guarda y reinicia el servicio"
    echo ""
else
    echo "✅ Todas las variables están correctamente configuradas"
    echo ""
    echo "Si la IA aún no responde, puede ser que:"
    echo "1. No se están recibiendo mensajes (verifica conexión WhatsApp)"
    echo "2. Hay un error en procesarConFlor (revisa logs con 'docker logs $CONTAINER_ID -f')"
    echo "3. El código necesita ser actualizado (subir whatsapp-server-baileys.js corregido)"
    echo ""
fi

echo "=========================================="
