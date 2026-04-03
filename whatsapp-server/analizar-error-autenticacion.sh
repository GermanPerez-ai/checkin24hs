#!/bin/bash
# 🔍 Analizar el error exacto de autenticación

cd /root/checkin24hs

echo "=============================================================="
echo "🔍 ANÁLISIS DEL ERROR DE AUTENTICACIÓN"
echo "=============================================================="
echo ""

# 1. Ver logs recientes buscando el error exacto
echo "1️⃣  Buscando errores de autenticación en los últimos logs..."
docker service logs checkin24hs_whatsapp --tail 200 | grep -A 10 -B 5 -iE "device_removed|conflict|timeout|428|401|515|error.*sync|sync.*error|app.*state" | tail -50
echo ""

# 2. Ver el flujo completo de autenticación
echo "2️⃣  Flujo completo de autenticación (últimos 100 logs)..."
docker service logs checkin24hs_whatsapp --tail 100 | grep -E "QR|escaneado|autenticación|conectado|sync|device_removed|conflict" | tail -30
echo ""

# 3. Verificar si hay patrones de error
echo "3️⃣  Patrones de error (contando ocurrencias)..."
echo "   device_removed:"
docker service logs checkin24hs_whatsapp --tail 500 | grep -c "device_removed" || echo "   0"
echo "   Stream Errored (conflict):"
docker service logs checkin24hs_whatsapp --tail 500 | grep -c "Stream Errored.*conflict" || echo "   0"
echo "   Error 428:"
docker service logs checkin24hs_whatsapp --tail 500 | grep -c "428" || echo "   0"
echo "   Error 401:"
docker service logs checkin24hs_whatsapp --tail 500 | grep -c "401" || echo "   0"
echo "   app state sync:"
docker service logs checkin24hs_whatsapp --tail 500 | grep -c "app.*state.*sync" || echo "   0"
echo ""

# 4. Verificar tiempo entre QR escaneado y error
echo "4️⃣  Tiempo entre QR escaneado y error..."
docker service logs checkin24hs_whatsapp --tail 200 | grep -E "QR escaneado|device_removed|conflict" | tail -10
echo ""

echo "=============================================================="
echo "📊 DIAGNÓSTICO"
echo "=============================================================="
echo ""

# Analizar qué error es más común
DEVICE_REMOVED_COUNT=$(docker service logs checkin24hs_whatsapp --tail 500 | grep -c "device_removed" || echo "0")
CONFLICT_COUNT=$(docker service logs checkin24hs_whatsapp --tail 500 | grep -c "Stream Errored.*conflict" || echo "0")
ERROR_428_COUNT=$(docker service logs checkin24hs_whatsapp --tail 500 | grep -c "428" || echo "0")

if [ "$DEVICE_REMOVED_COUNT" -gt 5 ] || [ "$CONFLICT_COUNT" -gt 5 ]; then
    echo "❌ PROBLEMA: Errores persistentes de device_removed o conflict"
    echo ""
    echo "💡 Esto indica que:"
    echo "   1. WhatsApp está detectando múltiples intentos de conexión"
    echo "   2. Hay un conflicto de sesión que no se resuelve"
    echo "   3. La sincronización del app state está causando problemas"
    echo ""
    echo "🔧 SOLUCIONES RECOMENDADAS:"
    echo ""
    echo "   A) Cambiar a Evolution API (más estable, maneja esto mejor)"
    echo "   B) Probar modo pasivo de Baileys (desactiva sincronización)"
    echo "   C) Cambiar a whatsapp-web.js (diferente enfoque)"
    echo ""
elif [ "$ERROR_428_COUNT" -gt 5 ]; then
    echo "❌ PROBLEMA: Errores 428 (Connection Terminated by Server)"
    echo ""
    echo "💡 Esto indica timeout durante autenticación"
    echo ""
    echo "🔧 SOLUCIONES:"
    echo "   A) Cambiar a Evolution API"
    echo "   B) Probar modo pasivo"
    echo ""
else
    echo "⚠️  No se encontraron patrones claros de error"
    echo "   Revisa los logs manualmente"
fi

echo ""
echo "=============================================================="
echo ""
