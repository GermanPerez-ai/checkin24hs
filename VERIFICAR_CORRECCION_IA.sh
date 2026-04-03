#!/bin/bash
# Script para verificar que la corrección de IA se aplicó correctamente

echo "=========================================="
echo "VERIFICAR CORRECCIÓN DE IA"
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

# 1. Verificar que el contenedor está corriendo
echo "=== PASO 1: ESTADO DEL CONTENEDOR ==="
echo ""
docker ps | grep $CONTAINER_ID
echo ""

# 2. Verificar que el código se actualizó
echo "=== PASO 2: VERIFICAR CÓDIGO ACTUALIZADO ==="
echo ""
echo "Verificando que AUTO_REPLY y FLOR_ENABLED respetan variables de entorno:"
docker exec $CONTAINER_ID grep -A 1 "AUTO_REPLY:" /app/whatsapp-server-baileys.js | head -2
docker exec $CONTAINER_ID grep -A 1 "FLOR_ENABLED:" /app/whatsapp-server-baileys.js | head -2
echo ""

# 3. Verificar variables de entorno
echo "=== PASO 3: VARIABLES DE ENTORNO ==="
echo ""
echo "Variables relacionadas con IA:"
docker exec $CONTAINER_ID env | grep -E "(AUTO_REPLY|FLOR_ENABLED|GEMINI_API_KEY|FLOR_DELAY)" | grep -v "PASSWORD\|SECRET"
echo ""

# 4. Verificar logs recientes
echo "=== PASO 4: LOGS RECIENTES (últimas 30 líneas) ==="
echo ""
docker logs $CONTAINER_ID --tail 30
echo ""

# 5. Verificar que WhatsApp está conectado
echo "=== PASO 5: ESTADO DE CONEXIÓN WHATSAPP ==="
echo ""
CONEXION=$(docker logs $CONTAINER_ID --tail 100 | grep -i "WhatsApp conectado\|connection.*open" | tail -1)
if [ -n "$CONEXION" ]; then
    echo "✅ $CONEXION"
else
    echo "⚠️ No se encontró mensaje de conexión exitosa en logs recientes"
fi
echo ""

# 6. Diagnóstico final
echo "=== DIAGNÓSTICO FINAL ==="
echo ""

AUTO_REPLY_ENV=$(docker exec $CONTAINER_ID env | grep "^AUTO_REPLY=" | cut -d'=' -f2)
FLOR_ENABLED_ENV=$(docker exec $CONTAINER_ID env | grep "^FLOR_ENABLED=" | cut -d'=' -f2)
GEMINI_KEY=$(docker exec $CONTAINER_ID env | grep "^GEMINI_API_KEY=" | cut -d'=' -f2)

# Verificar AUTO_REPLY
if [ -n "$AUTO_REPLY_ENV" ] && [ "$AUTO_REPLY_ENV" != "true" ] && [ "$AUTO_REPLY_ENV" != "1" ]; then
    echo "❌ AUTO_REPLY=$AUTO_REPLY_ENV (debe ser 'true' o '1')"
    echo "   Configura AUTO_REPLY=true en EasyPanel"
else
    echo "✅ AUTO_REPLY: OK"
fi

# Verificar FLOR_ENABLED
if [ -n "$FLOR_ENABLED_ENV" ] && [ "$FLOR_ENABLED_ENV" != "true" ] && [ "$FLOR_ENABLED_ENV" != "1" ]; then
    echo "❌ FLOR_ENABLED=$FLOR_ENABLED_ENV (debe ser 'true' o '1')"
    echo "   Configura FLOR_ENABLED=true en EasyPanel"
else
    echo "✅ FLOR_ENABLED: OK"
fi

# Verificar GEMINI_API_KEY
if [ -z "$GEMINI_KEY" ]; then
    echo "❌ GEMINI_API_KEY está vacía"
    echo "   Configura GEMINI_API_KEY en EasyPanel"
else
    echo "✅ GEMINI_API_KEY: Configurada"
fi

echo ""

echo "=========================================="
echo "PRÓXIMOS PASOS"
echo "=========================================="
echo ""
echo "1. Envía un mensaje de prueba a Flor por WhatsApp"
echo "2. Verifica los logs en tiempo real:"
echo "   docker logs $CONTAINER_ID -f"
echo ""
echo "Deberías ver:"
echo "   - 📱 Mensaje recibido de..."
echo "   - ⏱️ Procesando mensaje(s)..."
echo "   - ✅ Flor respondió a..."
echo ""
