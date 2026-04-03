#!/bin/bash
# 🔍 Verificar si los cambios están en el repositorio

echo "=============================================================="
echo "🔍 VERIFICANDO CAMBIOS EN EL REPOSITORIO"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Verificar si el archivo tiene la variable qrExpirationTimer
echo "1️⃣  Verificando variable qrExpirationTimer en el repositorio:"
grep -n "let qrExpirationTimer" whatsapp-server/whatsapp-server-baileys.js
echo ""

# 2. Verificar función start() en el repositorio
echo "2️⃣  Verificando función start() en el repositorio:"
grep -A 5 "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js | head -10
echo ""

# 3. Comparar con el archivo en el contenedor
echo "3️⃣  Comparando con el archivo en el contenedor:"
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   Variable en contenedor:"
docker exec $CONTAINER_ID sh -c "grep -n 'let qrExpirationTimer' /app/whatsapp-server-baileys.js" 2>/dev/null
echo "   Función start() en contenedor:"
docker exec $CONTAINER_ID sh -c "grep -A 3 'Iniciar servidor HTTP PRIMERO' /app/whatsapp-server-baileys.js" 2>/dev/null | head -5
echo ""

# 4. Verificar si hay diferencias
echo "4️⃣  Verificando diferencias entre repositorio y contenedor:"
REPO_LINES=$(wc -l < whatsapp-server/whatsapp-server-baileys.js)
CONTAINER_LINES=$(docker exec $CONTAINER_ID sh -c "wc -l < /app/whatsapp-server-baileys.js" 2>/dev/null)
echo "   Líneas en repositorio: $REPO_LINES"
echo "   Líneas en contenedor: $CONTAINER_LINES"
echo ""

# 5. Si son diferentes, copiar del contenedor al repositorio
if [ "$REPO_LINES" != "$CONTAINER_LINES" ]; then
    echo "5️⃣  ⚠️  Los archivos son diferentes. Copiando del contenedor al repositorio..."
    docker cp $CONTAINER_ID:/app/whatsapp-server-baileys.js whatsapp-server/whatsapp-server-baileys.js
    echo "   ✅ Archivo copiado"
    echo ""
    echo "   Ahora puedes hacer:"
    echo "   git add whatsapp-server/whatsapp-server-baileys.js"
    echo "   git commit -m 'Fix: Corregir error qrExpirationTimer y reordenar inicio del servidor HTTP'"
    echo "   git push"
else
    echo "5️⃣  ✅ Los archivos son idénticos. Los cambios ya están en el repositorio."
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
