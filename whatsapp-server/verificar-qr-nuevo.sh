#!/bin/bash
# 🔍 Verificar que el QR sea Nuevo (No Expirado)

echo "=============================================================="
echo "🔍 VERIFICANDO QUE EL QR SEA NUEVO"
echo "=============================================================="
echo ""

# 1. Obtener información del QR
echo "1️⃣  Obteniendo información del QR..."
QR_INFO=$(curl -s http://localhost:3001/api/qr 2>/dev/null)

if [ -z "$QR_INFO" ]; then
    echo "❌ No se pudo obtener información del QR"
    exit 1
fi

echo "$QR_INFO" | python3 -m json.tool 2>/dev/null || echo "$QR_INFO"
echo ""

# 2. Verificar estado
STATUS=$(echo "$QR_INFO" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
QR_AGE=$(echo "$QR_INFO" | grep -o '"qrAge":[0-9]*' | cut -d':' -f2)
EXPIRES_IN=$(echo "$QR_INFO" | grep -o '"expiresIn":[0-9]*' | cut -d':' -f2)

echo "2️⃣  Análisis del QR:"
echo "--------------------------------------------------------------"
echo "   Estado: $STATUS"

if [ -n "$QR_AGE" ]; then
    echo "   Edad: $QR_AGE minutos"
    if [ "$QR_AGE" -gt 2 ]; then
        echo "   ⚠️  QR EXPIrado (más de 2 minutos)"
        echo "   💡 Necesitas regenerar el QR"
    elif [ "$QR_AGE" -gt 0 ]; then
        echo "   ⚠️  QR tiene $QR_AGE minutos (puede estar expirando)"
    else
        echo "   ✅ QR es nuevo (menos de 1 minuto)"
    fi
fi

if [ -n "$EXPIRES_IN" ]; then
    MINUTES=$(($EXPIRES_IN / 60))
    SECONDS=$(($EXPIRES_IN % 60))
    echo "   Expira en: ${MINUTES}m ${SECONDS}s"
    
    if [ "$EXPIRES_IN" -lt 30 ]; then
        echo "   ⚠️  QR expirará pronto - escanéalo AHORA"
    fi
fi
echo ""

# 3. Recomendación
echo "3️⃣  Recomendación:"
echo "--------------------------------------------------------------"

if [ "$STATUS" = "expired" ] || ([ -n "$QR_AGE" ] && [ "$QR_AGE" -gt 2 ]); then
    echo "   ❌ Este QR está EXPIRADO"
    echo ""
    echo "   🔧 SOLUCIÓN:"
    echo "   1. Regenera el QR:"
    echo "      curl -X POST http://localhost:3001/api/qr/regenerate"
    echo ""
    echo "   2. O limpia la sesión y reinicia:"
    echo "      CONTAINER_ID=\$(docker ps | grep checkin24hs_whatsapp | awk '{print \$1}' | head -1)"
    echo "      docker exec \$CONTAINER_ID rm -rf /app/auth_info_baileys_1"
    echo "      docker service update --force checkin24hs_whatsapp"
    echo ""
    echo "   3. Espera 30-60 segundos"
    echo "   4. Verifica que el nuevo QR tenga menos de 1 minuto de edad"
    echo "   5. Escanéalo INMEDIATAMENTE"
elif [ "$STATUS" = "waiting_scan" ]; then
    if [ -n "$EXPIRES_IN" ] && [ "$EXPIRES_IN" -gt 60 ]; then
        echo "   ✅ QR es NUEVO y válido"
        echo "   📱 Puedes escanearlo ahora"
    else
        echo "   ⚠️  QR puede estar expirando"
        echo "   📱 Escanéalo INMEDIATAMENTE"
    fi
elif [ "$STATUS" = "connected" ]; then
    echo "   ✅ WhatsApp ya está conectado"
    echo "   📱 No necesitas escanear QR"
else
    echo "   ⏳ Esperando que se genere el QR..."
    echo "   💡 Espera 30-60 segundos y vuelve a verificar"
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
