#!/bin/bash
# 🔍 Verificar función start() en el contenedor

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

echo "=============================================================="
echo "🔍 VERIFICANDO FUNCIÓN start() EN CONTENEDOR"
echo "=============================================================="
echo ""

# Buscar función start
echo "1️⃣  Buscando función start()..."
docker exec $CONTAINER_ID sh -c "grep -n 'async function start' /app/whatsapp-server-baileys.js"
echo ""

# Ver función start completa
START_LINE=$(docker exec $CONTAINER_ID sh -c "grep -n 'async function start' /app/whatsapp-server-baileys.js" | cut -d: -f1)
echo "2️⃣  Función start() en línea $START_LINE"
echo "   Mostrando líneas $START_LINE a $((START_LINE + 20)):"
docker exec $CONTAINER_ID sh -c "sed -n '${START_LINE},$((START_LINE + 20))p' /app/whatsapp-server-baileys.js"
echo ""

# Verificar si usa qrExpirationTimer
echo "3️⃣  Verificando uso de qrExpirationTimer en función start..."
docker exec $CONTAINER_ID sh -c "sed -n '${START_LINE},$((START_LINE + 20))p' /app/whatsapp-server-baileys.js | grep -n 'qrExpirationTimer'"
echo ""

# Ver orden de declaración de variables
echo "4️⃣  Orden de variables globales:"
docker exec $CONTAINER_ID sh -c "grep -n '^let ' /app/whatsapp-server-baileys.js | head -10"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
