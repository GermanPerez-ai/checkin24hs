#!/bin/bash
# 📱 Obtener QR Actual del Servicio

echo "=============================================================="
echo "📱 OBTENER QR ACTUAL"
echo "=============================================================="
echo ""

# 1. Verificar que el servicio responda
echo "1️⃣  Verificando que el servicio responda..."
HEALTH=$(timeout 10 curl -s --max-time 5 http://localhost:3001/api/health 2>&1)

if echo "$HEALTH" | grep -q "ok\|status"; then
    echo "   ✅ Servicio responde"
else
    echo "   ⚠️  Servicio no responde o tarda mucho"
    echo "   Respuesta: $HEALTH"
    echo ""
    echo "   Intentando desde el host..."
    timeout 10 curl -s --max-time 5 http://127.0.0.1:3001/api/health 2>&1 || echo "   ❌ No responde"
fi
echo ""

# 2. Obtener información del QR
echo "2️⃣  Obteniendo información del QR..."
QR_INFO=$(timeout 10 curl -s --max-time 5 http://localhost:3001/api/qr 2>&1)

if [ -z "$QR_INFO" ] || echo "$QR_INFO" | grep -q "timeout\|refused\|error"; then
    echo "   ⚠️  No se pudo obtener el QR"
    echo "   Respuesta: $QR_INFO"
    echo ""
    echo "   Verificando logs recientes..."
    docker service logs checkin24hs_whatsapp --tail 10 | grep -E "QR|Servidor iniciado"
else
    echo "   ✅ QR obtenido"
    echo ""
    echo "$QR_INFO" | python3 -m json.tool 2>/dev/null || echo "$QR_INFO"
fi
echo ""

# 3. Verificar estado de conexión
echo "3️⃣  Verificando estado de conexión..."
STATUS=$(timeout 10 curl -s --max-time 5 http://localhost:3001/api/status 2>&1)

if [ -n "$STATUS" ] && ! echo "$STATUS" | grep -q "timeout\|refused\|error"; then
    echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
else
    echo "   ⚠️  No se pudo obtener el estado"
fi
echo ""

# 4. Verificar logs recientes del QR
echo "4️⃣  Últimos logs relacionados con QR..."
docker service logs checkin24hs_whatsapp --tail 20 | grep -E "QR Code|Servidor iniciado|connected" | tail -5
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "💡 Si el servicio no responde, puede estar:"
echo "   1. Iniciando (espera 30-60 segundos más)"
echo "   2. Bloqueado (reinicia el servicio)"
echo "   3. Con problemas de red (verifica el puerto)"
echo ""
