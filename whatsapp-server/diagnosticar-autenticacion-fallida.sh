#!/bin/bash
# 🔍 Diagnosticar por qué falla la autenticación

echo "=============================================================="
echo "🔍 DIAGNÓSTICO: AUTENTICACIÓN FALLIDA"
echo "=============================================================="
echo ""

cd /root/checkin24hs

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

# 1. Ver logs recientes buscando errores de autenticación
echo "1️⃣  Logs recientes (últimos 50):"
docker logs $CONTAINER_ID --tail 50 2>&1 | grep -E "QR escaneado|autenticación|authentication|Error|error|428|Connection Terminated|Timed Out|timeout" | tail -20
echo ""

# 2. Verificar estado actual
echo "2️⃣  Estado actual del servidor:"
timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/status | python3 -m json.tool 2>/dev/null || echo "No responde"
echo ""

# 3. Buscar errores específicos de timeout
echo "3️⃣  Errores de timeout o conexión:"
docker logs $CONTAINER_ID 2>&1 | grep -iE "timed out|timeout|connection terminated|428|autenticación.*tardando" | tail -10
echo ""

# 4. Verificar si hay sesión guardada
echo "4️⃣  Verificando sesión guardada:"
docker exec $CONTAINER_ID sh -c "ls -la /app/auth_info_baileys_* 2>/dev/null | head -5 || echo 'No hay sesiones guardadas'"
echo ""

# 5. Ver logs completos del proceso de autenticación
echo "5️⃣  Proceso de autenticación completo:"
docker logs $CONTAINER_ID 2>&1 | grep -A 5 -B 5 "QR escaneado" | tail -30
echo ""

# 6. Verificar timeouts configurados en el código
echo "6️⃣  Verificando timeouts configurados:"
docker exec $CONTAINER_ID sh -c "grep -E 'timeout|Timeout|TIMEOUT' /app/whatsapp-server-baileys.js | grep -E 'connectTimeoutMs|defaultQueryTimeoutMs|appStateSyncTimeoutMs|keepAliveIntervalMs' | head -10" 2>/dev/null
echo ""

# 7. Verificar si el proceso se está reconectando
echo "7️⃣  Intentos de reconexión:"
docker logs $CONTAINER_ID 2>&1 | grep -iE "reconectando|reconnecting|reconnect" | tail -10
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
