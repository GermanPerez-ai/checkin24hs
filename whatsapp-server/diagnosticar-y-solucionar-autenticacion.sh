#!/bin/bash
# Diagnóstico completo y solución para problema de autenticación WhatsApp

cd /root/checkin24hs

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

echo "🔍 DIAGNÓSTICO COMPLETO DE AUTENTICACIÓN WHATSAPP"
echo "=============================================================="
echo ""

# 1. Verificar configuración del modo pasivo
echo "1️⃣  Verificando modo pasivo:"
echo "   - passive: true:"
docker exec "$CONTAINER" grep -n "passive: true" /app/whatsapp-server-baileys.js 2>/dev/null | head -1
echo "   - shouldSyncAppState: () => false:"
docker exec "$CONTAINER" grep -n "shouldSyncAppState: () => false" /app/whatsapp-server-baileys.js 2>/dev/null | head -1
echo "   - fireInitQueries: false:"
docker exec "$CONTAINER" grep -n "fireInitQueries: false" /app/whatsapp-server-baileys.js 2>/dev/null | head -1
echo ""

# 2. Verificar sesiones existentes
echo "2️⃣  Verificando sesiones existentes:"
INSTANCE_NUM=$(docker exec "$CONTAINER" grep -oP "INSTANCE_NUMBER.*?\|\|.*?\K\d+" /app/whatsapp-server-baileys.js 2>/dev/null | head -1 || echo "1")
echo "   Instancia: $INSTANCE_NUM"
docker exec "$CONTAINER" ls -la /app/auth_info_baileys_${INSTANCE_NUM} 2>/dev/null | head -5
echo ""

# 3. Verificar logs recientes para errores
echo "3️⃣  Errores en los últimos 50 logs:"
echo "   - device_removed:"
docker logs --tail 50 "$CONTAINER" 2>&1 | grep -i "device_removed" | tail -3
echo "   - Error 401:"
docker logs --tail 50 "$CONTAINER" 2>&1 | grep -i "401" | tail -3
echo "   - Error 428:"
docker logs --tail 50 "$CONTAINER" 2>&1 | grep -i "428" | tail -3
echo "   - Stream Errored:"
docker logs --tail 50 "$CONTAINER" 2>&1 | grep -i "Stream Errored" | tail -3
echo ""

# 4. Ver logs completos de la última conexión
echo "4️⃣  Últimos logs de conexión:"
docker logs --tail 100 "$CONTAINER" 2>&1 | tail -30
echo ""

echo "=============================================================="
echo "🔧 SOLUCIÓN RECOMENDADA"
echo "=============================================================="
echo ""
echo "El problema probablemente es:"
echo "   1. Sesión conflictiva existente en el servidor"
echo "   2. Otra sesión activa en WhatsApp (Web u otro servidor)"
echo "   3. El modo pasivo no está completamente aplicado"
echo ""
echo "Ejecuta este script para SOLUCIONAR:"
echo "   bash whatsapp-server/limpiar-sesion-y-reconectar.sh"
echo ""
