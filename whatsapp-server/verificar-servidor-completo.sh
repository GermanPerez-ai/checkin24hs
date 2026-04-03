#!/bin/bash
# ✅ Verificación completa del servidor

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETA DEL SERVIDOR"
echo "=============================================================="
echo ""

# 1. Verificar health
echo "1️⃣  Verificando /api/health..."
HEALTH=$(timeout 5 curl -s --max-time 3 http://localhost:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde: $HEALTH"
else
    echo "   ❌ Servidor no responde"
fi
echo ""

# 2. Verificar status
echo "2️⃣  Verificando /api/status..."
STATUS=$(timeout 5 curl -s --max-time 3 http://localhost:3001/api/status 2>/dev/null)
if [ -n "$STATUS" ]; then
    echo "   ✅ Status obtenido:"
    echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
else
    echo "   ❌ No se pudo obtener status"
fi
echo ""

# 3. Verificar QR
echo "3️⃣  Verificando /api/qr..."
QR=$(timeout 5 curl -s --max-time 3 http://localhost:3001/api/qr 2>/dev/null)
if [ -n "$QR" ]; then
    echo "   ✅ QR obtenido (primeros 100 caracteres):"
    echo "$QR" | head -c 100
    echo "..."
else
    echo "   ❌ No se pudo obtener QR"
fi
echo ""
echo ""

# 4. Verificar logs recientes
echo "4️⃣  Últimos logs del servidor:"
docker service logs checkin24hs_whatsapp --tail 5 | grep -E "Servidor iniciado|QR|Error|error" | tail -3
echo ""

# 5. Verificar mapeo de puertos
echo "5️⃣  Mapeo de puertos:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool 2>/dev/null | grep -E "PublishedPort|TargetPort"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "🌐 El servidor debería ser accesible en:"
echo "   - http://localhost:3001/api/health"
echo "   - http://localhost:3001/api/status"
echo "   - http://localhost:3001/api/qr"
echo ""
echo "📱 Si accedes desde fuera del servidor, usa la IP pública del servidor"
echo "   en lugar de localhost"
echo ""
