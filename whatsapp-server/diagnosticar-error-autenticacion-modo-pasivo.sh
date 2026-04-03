#!/bin/bash
# Diagnosticar error de autenticación con modo pasivo

cd /root/checkin24hs

echo "=============================================================="
echo "🔍 DIAGNÓSTICO DE ERROR DE AUTENTICACIÓN"
echo "=============================================================="
echo ""

# 1. Verificar que el modo pasivo esté activo
echo "1️⃣  Verificando modo pasivo en el código..."
CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

if [ ! -z "$CONTAINER" ]; then
    echo "   Verificando passive: true..."
    docker exec "$CONTAINER" grep -q "passive: true" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ passive: true encontrado" || echo "   ❌ passive: true NO encontrado"
    
    echo "   Verificando shouldSyncAppState: () => false..."
    docker exec "$CONTAINER" grep -q "shouldSyncAppState: () => false" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ shouldSyncAppState: () => false encontrado" || echo "   ❌ shouldSyncAppState: () => false NO encontrado"
    
    echo "   Verificando fireInitQueries: false..."
    docker exec "$CONTAINER" grep -q "fireInitQueries: false" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ fireInitQueries: false encontrado" || echo "   ❌ fireInitQueries: false NO encontrado"
else
    echo "   ❌ No se encontró contenedor"
fi
echo ""

# 2. Ver logs recientes de autenticación
echo "2️⃣  Logs recientes de autenticación (últimos 5 minutos)..."
docker service logs checkin24hs_whatsapp --since 5m --tail 100 | grep -E "QR|escaneado|autenticación|conectado|sync|device_removed|conflict|error|Error|428|401|515|timeout|MODO PASIVO|Modo pasivo" | tail -30
echo ""

# 3. Ver errores específicos
echo "3️⃣  Errores específicos encontrados..."
echo "   device_removed:"
docker service logs checkin24hs_whatsapp --since 10m --tail 200 | grep -c "device_removed" || echo "   0"
echo "   Error 428:"
docker service logs checkin24hs_whatsapp --since 10m --tail 200 | grep -c "428" || echo "   0"
echo "   Error 401:"
docker service logs checkin24hs_whatsapp --since 10m --tail 200 | grep -c "401" || echo "   0"
echo "   Connection Terminated:"
docker service logs checkin24hs_whatsapp --since 10m --tail 200 | grep -c "Connection Terminated" || echo "   0"
echo ""

# 4. Ver el flujo completo después de escanear QR
echo "4️⃣  Flujo completo después de escanear QR..."
docker service logs checkin24hs_whatsapp --since 10m --tail 200 | grep -A 20 "QR escaneado\|QR.*escaneado\|escaneado\|QR Code.*escaneado" | tail -50
echo ""

# 5. Verificar si hay sesión conflictiva
echo "5️⃣  Verificando sesiones existentes..."
if [ ! -z "$CONTAINER" ]; then
    docker exec "$CONTAINER" ls -la /app/auth_info_baileys_* 2>/dev/null | head -10 || echo "   No se encontraron sesiones"
fi
echo ""

# 6. Ver logs completos de los últimos intentos
echo "6️⃣  Logs completos de los últimos 2 minutos..."
docker service logs checkin24hs_whatsapp --since 2m --tail 50
echo ""

echo "=============================================================="
echo "📊 RESUMEN"
echo "=============================================================="
echo ""
echo "Si el modo pasivo está activo pero aún falla, puede ser:"
echo "   1. Sesión conflictiva anterior (necesita limpiarse)"
echo "   2. Problema de red/conectividad"
echo "   3. WhatsApp detectando múltiples intentos"
echo ""
echo "💡 SOLUCIÓN: Limpiar sesión y reintentar"
echo "   Ejecuta: ./whatsapp-server/limpiar-sesion-y-reconectar.sh"
