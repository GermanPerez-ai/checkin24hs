#!/bin/bash
# ✅ Verificar que todo funcione después del redeploy

echo "=============================================================="
echo "✅ VERIFICACIÓN POST-REDEPLOY"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Esperar a que el servicio esté listo
echo "1️⃣  Esperando a que el servicio esté listo (60 segundos)..."
sleep 60
echo "   ✅ Espera completada"
echo ""

# 2. Verificar estado del servicio
echo "2️⃣  Estado del servicio Docker Swarm:"
docker service ps checkin24hs_whatsapp --no-trunc | head -3
echo ""

# 3. Verificar contenedor
echo "3️⃣  Contenedor actual:"
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   Contenedor: $CONTAINER_ID"
echo ""

# 4. Verificar logs de inicio
echo "4️⃣  Logs de inicio del servidor:"
docker logs $CONTAINER_ID 2>&1 | grep -E "Servidor iniciado|Iniciando servidor|Error|error" | head -10
echo ""

# 5. Verificar que el servidor responda
echo "5️⃣  Verificando que el servidor responda:"
for i in {1..5}; do
    echo "   Intento $i/5..."
    RESPONSE=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>/dev/null)
    if [ -n "$RESPONSE" ]; then
        echo "   ✅ Servidor responde: $RESPONSE"
        break
    else
        echo "   ⏳ Esperando... (intento $i/5)"
        sleep 10
    fi
done
echo ""

# 6. Verificar endpoints
echo "6️⃣  Verificando endpoints:"
echo "   a) /api/health:"
timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health | python3 -m json.tool 2>/dev/null || echo "   ❌ No responde"
echo ""
echo "   b) /api/status:"
timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/status | python3 -m json.tool 2>/dev/null | head -10 || echo "   ❌ No responde"
echo ""

# 7. Verificar código en el contenedor
echo "7️⃣  Verificando código en el contenedor:"
echo "   Variable qrExpirationTimer:"
docker exec $CONTAINER_ID sh -c "grep -n 'let qrExpirationTimer' /app/whatsapp-server-baileys.js" 2>/dev/null && echo "   ✅ Variable encontrada" || echo "   ❌ Variable no encontrada"
echo ""
echo "   Función start() actualizada:"
docker exec $CONTAINER_ID sh -c "grep -A 3 'Iniciar servidor HTTP PRIMERO' /app/whatsapp-server-baileys.js" 2>/dev/null | head -3 && echo "   ✅ Función actualizada" || echo "   ❌ Función no actualizada"
echo ""

# 8. Verificar puerto
echo "8️⃣  Verificando puerto 3001:"
ss -tuln | grep 3001 && echo "   ✅ Puerto escuchando" || echo "   ❌ Puerto no escuchando"
echo ""

# 9. Verificar QR disponible
echo "9️⃣  Verificando disponibilidad de QR:"
QR_RESPONSE=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/qr 2>/dev/null)
if [ -n "$QR_RESPONSE" ]; then
    echo "   ✅ QR disponible"
    echo "$QR_RESPONSE" | python3 -m json.tool 2>/dev/null | grep -E "status|qr" | head -3
else
    echo "   ⚠️  QR aún no disponible (puede tardar unos segundos más)"
fi
echo ""

# 10. Resumen
echo "=============================================================="
echo "📋 RESUMEN"
echo "=============================================================="
echo ""

# Verificar errores en logs
ERRORS=$(docker logs $CONTAINER_ID 2>&1 | grep -iE "error|exception|failed" | tail -5)
if [ -n "$ERRORS" ]; then
    echo "⚠️  Errores encontrados en logs:"
    echo "$ERRORS"
    echo ""
else
    echo "✅ No se encontraron errores en los logs"
    echo ""
fi

# Verificar que el servidor responda
FINAL_CHECK=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>/dev/null)
if [ -n "$FINAL_CHECK" ]; then
    echo "✅ Servidor funcionando correctamente"
    echo "🌐 Accesible en:"
    echo "   - http://127.0.0.1:3001/api/health"
    echo "   - http://127.0.0.1:3001/api/status"
    echo "   - http://127.0.0.1:3001/api/qr"
    echo ""
    echo "📱 Próximo paso: Escanear el QR code para conectar WhatsApp"
else
    echo "❌ Servidor no responde. Revisa los logs:"
    echo "   docker logs $CONTAINER_ID --tail 50"
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
