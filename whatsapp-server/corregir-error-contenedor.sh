#!/bin/bash
# Corregir error de sintaxis en el contenedor

cd /root/checkin24hs

echo "🔧 Corrigiendo error de sintaxis en el contenedor..."
echo ""

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# Verificar qué archivo está usando realmente
echo "1️⃣  Verificando archivos en el contenedor..."
docker exec "$CONTAINER" ls -la /app/*.js 2>/dev/null | head -10
echo ""

# El error dice /app/whatsapp-server-baileys.js (sin subdirectorio)
# Verificar si existe
echo "2️⃣  Verificando /app/whatsapp-server-baileys.js..."
if docker exec "$CONTAINER" test -f /app/whatsapp-server-baileys.js 2>/dev/null; then
    echo "   ✅ Archivo existe en /app/whatsapp-server-baileys.js"
    FILE_PATH="/app/whatsapp-server-baileys.js"
elif docker exec "$CONTAINER" test -f /app/whatsapp-server/whatsapp-server-baileys.js 2>/dev/null; then
    echo "   ✅ Archivo existe en /app/whatsapp-server/whatsapp-server-baileys.js"
    FILE_PATH="/app/whatsapp-server/whatsapp-server-baileys.js"
else
    echo "   ❌ No se encontró el archivo"
    exit 1
fi

echo ""
echo "3️⃣  Verificando línea 298 del archivo en contenedor..."
docker exec "$CONTAINER" sed -n '295,305p' "$FILE_PATH" 2>/dev/null
echo ""

echo "4️⃣  Buscando catch huérfanos..."
docker exec "$CONTAINER" grep -n "} catch" "$FILE_PATH" 2>/dev/null | head -10
echo ""

echo "5️⃣  Copiando archivo corregido..."
# Copiar a ambas ubicaciones posibles
docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server-baileys.js"
docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server/whatsapp-server-baileys.js"
echo "   ✅ Archivo copiado a ambas ubicaciones"
echo ""

echo "6️⃣  Verificando sintaxis en contenedor..."
docker exec "$CONTAINER" node -c "$FILE_PATH" 2>&1 && echo "   ✅ Sintaxis correcta" || echo "   ❌ Aún hay errores"
echo ""

echo "✅ Corrección aplicada. El contenedor debería reiniciarse automáticamente."
