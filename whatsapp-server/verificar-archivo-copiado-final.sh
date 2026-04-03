#!/bin/bash
# ✅ Verificar que el archivo está correctamente copiado

cd /root/checkin24hs

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

echo "=============================================================="
echo "🔍 VERIFICACIÓN FINAL DEL ARCHIVO"
echo "=============================================================="
echo ""

echo "Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣  Verificando connectionTimestamp..."
docker exec $CONTAINER_ID sh -c "grep -n 'connectionTimestamp = null' /app/whatsapp-server-baileys.js | head -1"
echo ""

echo "2️⃣  Verificando protección de 15 minutos..."
docker exec $CONTAINER_ID sh -c "grep -n 'minutesSinceConnection < 15' /app/whatsapp-server-baileys.js"
echo ""

echo "3️⃣  Verificando protección durante sincronización..."
docker exec $CONTAINER_ID sh -c "grep -n 'Error durante sincronización del app state' /app/whatsapp-server-baileys.js"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
