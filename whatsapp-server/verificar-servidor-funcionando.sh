#!/bin/bash
# ✅ Verificar que el servidor esté funcionando correctamente

echo "=============================================================="
echo "✅ VERIFICANDO SERVIDOR"
echo "=============================================================="
echo ""

# 1. Verificar health
echo "1️⃣  Verificando /api/health..."
HEALTH=$(timeout 10 curl -s --max-time 5 http://localhost:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde: $HEALTH"
else
    echo "   ❌ Servidor no responde"
fi
echo ""

# 2. Verificar status
echo "2️⃣  Verificando /api/status..."
STATUS=$(timeout 10 curl -s --max-time 5 http://localhost:3001/api/status 2>/dev/null)
if [ -n "$STATUS" ]; then
    echo "   ✅ Status obtenido:"
    echo "$STATUS" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
else
    echo "   ❌ No se pudo obtener status"
fi
echo ""

# 3. Verificar logs recientes
echo "3️⃣  Verificando logs recientes..."
echo "   Buscando errores..."
docker service logs checkin24hs_whatsapp --tail 30 | grep -iE "error|exception|qrExpirationTimer" || echo "   ✅ No se encontraron errores relacionados"
echo ""

# 4. Verificar que el servidor inició
echo "4️⃣  Verificando inicio del servidor..."
docker service logs checkin24hs_whatsapp --tail 20 | grep -E "Servidor iniciado|Iniciando servidor" | tail -1
echo ""

# 5. Verificar contenedor actual
echo "5️⃣  Contenedor actual:"
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   $CONTAINER_ID"
echo ""

# 6. Verificar que el archivo tiene la variable
echo "6️⃣  Verificando variable qrExpirationTimer en contenedor..."
docker exec $CONTAINER_ID sh -c "grep -n 'let qrExpirationTimer' /app/whatsapp-server-baileys.js" && echo "   ✅ Variable encontrada" || echo "   ❌ Variable no encontrada"
echo ""

# 7. Verificar función start
echo "7️⃣  Verificando función start()..."
START_LINE=$(docker exec $CONTAINER_ID sh -c "grep -n 'async function start' /app/whatsapp-server-baileys.js" | cut -d: -f1 | head -1)
if [ -n "$START_LINE" ]; then
    echo "   Función start() en línea $START_LINE"
    docker exec $CONTAINER_ID sh -c "sed -n '${START_LINE},$((START_LINE + 10))p' /app/whatsapp-server-baileys.js" | grep -q "Iniciar servidor HTTP PRIMERO" && echo "   ✅ Función start() actualizada correctamente" || echo "   ⚠️  Función start() puede no estar actualizada"
else
    echo "   ❌ No se encontró función start()"
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
