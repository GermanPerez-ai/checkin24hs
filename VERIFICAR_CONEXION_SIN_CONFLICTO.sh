#!/bin/bash
# Verificar que la conexión esté estable sin errores de conflicto

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR CONEXIÓN SIN CONFLICTO"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver estado actual
echo "1. Estado actual de la conexión..."
echo ""
docker logs $CONTAINER_ID --tail 30 | grep -E "✅|❌|🔄|📱|QR|conectado|conflict" | tail -15
echo ""

# 2. Verificar si hay errores de conflicto
echo "2. Verificando errores de conflicto..."
echo ""
CONFLICTOS=$(docker logs $CONTAINER_ID --tail 100 | grep -c "Stream Errored (conflict)" || echo "0")
if [ "$CONFLICTOS" -gt "0" ]; then
    echo "⚠️ Se encontraron $CONFLICTOS errores de conflicto en los últimos logs"
    echo "   Asegúrate de haber cerrado TODAS las sesiones de WhatsApp Web en tu teléfono"
else
    echo "✅ No se encontraron errores de conflicto recientes"
fi
echo ""

# 3. Verificar si está conectado
echo "3. Verificando estado de conexión..."
echo ""
ESTADO=$(docker logs $CONTAINER_ID --tail 20 | grep -E "WhatsApp conectado exitosamente|Estado:" | tail -1)
if [ -z "$ESTADO" ]; then
    echo "⚠️ No se encontró estado de conexión. Espera unos segundos y verifica de nuevo."
else
    echo "$ESTADO"
fi
echo ""

echo "=========================================="
echo "PRÓXIMOS PASOS"
echo "=========================================="
echo ""
echo "1. Si ves un QR code en los logs, escanéalo desde tu teléfono"
echo "2. Espera a que aparezca '✅ WhatsApp conectado exitosamente'"
echo "3. Verifica que NO aparezcan más errores de 'Stream Errored (conflict)'"
echo "4. Una vez conectado sin errores, envía un mensaje de prueba"
echo "5. Verifica los logs con: docker logs $CONTAINER_ID --tail 50 | grep -E '📨|📱|Mensaje recibido'"
echo ""
