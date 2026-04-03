#!/bin/bash
# 🔍 Verificar código dentro del contenedor

echo "=============================================================="
echo "🔍 VERIFICANDO CÓDIGO EN EL CONTENEDOR"
echo "=============================================================="
echo ""

# Obtener contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "1️⃣  Contenedor: $CONTAINER_ID"
echo ""

# Verificar si tiene la variable qrExpirationTimer
echo "2️⃣  Verificando variable qrExpirationTimer en el contenedor..."
docker exec $CONTAINER_ID sh -c "grep -n 'qrExpirationTimer' /app/whatsapp-server-baileys.js | head -3" 2>&1
echo ""

# Verificar líneas alrededor de donde debería estar (línea 100)
echo "3️⃣  Verificando variables globales (líneas 95-105)..."
docker exec $CONTAINER_ID sh -c "sed -n '95,105p' /app/whatsapp-server-baileys.js" 2>&1
echo ""

# Verificar función start (línea 800-810)
echo "4️⃣  Verificando función start (línea 800-810)..."
docker exec $CONTAINER_ID sh -c "sed -n '800,810p' /app/whatsapp-server-baileys.js" 2>&1
echo ""

# Verificar cuántas líneas tiene el archivo
echo "5️⃣  Total de líneas del archivo en el contenedor:"
docker exec $CONTAINER_ID sh -c "wc -l /app/whatsapp-server-baileys.js" 2>&1
echo ""

# Verificar código en GitHub (local)
echo "6️⃣  Verificando código en el repositorio local..."
cd /root/checkin24hs
grep -n "qrExpirationTimer" whatsapp-server/whatsapp-server-baileys.js | head -3
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
