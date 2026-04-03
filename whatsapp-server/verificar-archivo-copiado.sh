#!/bin/bash
# 🔍 Verificar si el archivo se copió correctamente

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

echo "=============================================================="
echo "🔍 VERIFICANDO ARCHIVO COPIADO"
echo "=============================================================="
echo ""

echo "1️⃣  Contenedor actual: $CONTAINER_ID"
echo ""

# Verificar si tiene la variable
echo "2️⃣  Verificando variable qrExpirationTimer..."
docker exec $CONTAINER_ID sh -c "grep -n 'let qrExpirationTimer' /app/whatsapp-server-baileys.js"
echo ""

# Ver función start
echo "3️⃣  Verificando función start()..."
START_LINE=$(docker exec $CONTAINER_ID sh -c "grep -n 'async function start' /app/whatsapp-server-baileys.js" | cut -d: -f1 | head -1)
echo "   Función start() en línea $START_LINE"
docker exec $CONTAINER_ID sh -c "sed -n '${START_LINE},$((START_LINE + 15))p' /app/whatsapp-server-baileys.js"
echo ""

# Ver cuántas líneas tiene
echo "4️⃣  Total de líneas:"
docker exec $CONTAINER_ID sh -c "wc -l /app/whatsapp-server-baileys.js"
echo ""

# Comparar con el archivo local
echo "5️⃣  Comparando con archivo local..."
echo "   Archivo local:"
wc -l /root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js
echo "   Archivo contenedor:"
docker exec $CONTAINER_ID sh -c "wc -l /app/whatsapp-server-baileys.js"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
