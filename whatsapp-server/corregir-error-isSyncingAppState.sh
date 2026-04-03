#!/bin/bash
# Corregir error isSyncingAppState is not defined

cd /root/checkin24hs

echo "🔧 Corrigiendo error isSyncingAppState..."
echo ""

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar que las variables estén en el archivo local
echo "1️⃣  Verificando variables en archivo local..."
if grep -q "let isSyncingAppState" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ isSyncingAppState encontrado en archivo local"
else
    echo "   ❌ isSyncingAppState NO encontrado en archivo local"
    echo "   🔧 Agregando variable..."
    sed -i '/let connectionStatus =/a let isSyncingAppState = false; // Flag para indicar que está sincronizando app state' whatsapp-server/whatsapp-server-baileys.js
    sed -i '/let isSyncingAppState =/a let connectionTimestamp = null; // Timestamp de cuando se conectó exitosamente' whatsapp-server/whatsapp-server-baileys.js
fi

if grep -q "let connectionTimestamp" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ connectionTimestamp encontrado en archivo local"
else
    echo "   ❌ connectionTimestamp NO encontrado en archivo local"
    echo "   🔧 Agregando variable..."
    sed -i '/let isSyncingAppState =/a let connectionTimestamp = null; // Timestamp de cuando se conectó exitosamente' whatsapp-server/whatsapp-server-baileys.js
fi
echo ""

# 2. Copiar archivo corregido al contenedor
echo "2️⃣  Copiando archivo corregido al contenedor..."
docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server-baileys.js"
echo "   ✅ Archivo copiado"
echo ""

# 3. Verificar que las variables estén en el contenedor
echo "3️⃣  Verificando variables en contenedor..."
docker exec "$CONTAINER" grep -q "let isSyncingAppState" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ isSyncingAppState encontrado en contenedor" || echo "   ❌ isSyncingAppState NO encontrado en contenedor"
docker exec "$CONTAINER" grep -q "let connectionTimestamp" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ connectionTimestamp encontrado en contenedor" || echo "   ❌ connectionTimestamp NO encontrado en contenedor"
echo ""

# 4. Limpiar sesión conflictiva
echo "4️⃣  Limpiando sesión conflictiva anterior..."
docker exec "$CONTAINER" rm -rf /app/auth_info_baileys_* 2>/dev/null
echo "   ✅ Sesión limpiada"
echo ""

# 5. Verificar sintaxis
echo "5️⃣  Verificando sintaxis..."
docker exec "$CONTAINER" node -c /app/whatsapp-server-baileys.js 2>&1 && echo "   ✅ Sintaxis correcta" || echo "   ❌ Aún hay errores de sintaxis"
echo ""

echo "✅ Corrección aplicada"
echo ""
echo "🔄 El servidor debería reiniciarse automáticamente"
echo "   Espera unos segundos y recarga la página para ver el nuevo QR code"
