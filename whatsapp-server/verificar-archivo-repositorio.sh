#!/bin/bash
# 🔍 Verificar archivo en el repositorio

echo "=============================================================="
echo "🔍 VERIFICANDO ARCHIVO EN REPOSITORIO"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Verificar si existe
if [ ! -f "whatsapp-server/whatsapp-server-baileys.js" ]; then
    echo "❌ Archivo no encontrado"
    exit 1
fi

# 2. Ver cuántas líneas tiene
TOTAL_LINES=$(wc -l < whatsapp-server/whatsapp-server-baileys.js)
echo "1️⃣  Total de líneas: $TOTAL_LINES"
echo ""

# 3. Buscar la función start
echo "2️⃣  Buscando función 'start'..."
echo "--------------------------------------------------------------"
grep -n "async function start" whatsapp-server/whatsapp-server-baileys.js
echo ""

# 4. Ver el contenido alrededor de la función start
START_LINE=$(grep -n "async function start" whatsapp-server/whatsapp-server-baileys.js | cut -d: -f1)
if [ -n "$START_LINE" ]; then
    echo "3️⃣  Función start encontrada en línea $START_LINE"
    echo "   Mostrando líneas $START_LINE a $((START_LINE + 35)):"
    echo "--------------------------------------------------------------"
    sed -n "${START_LINE},$((START_LINE + 35))p" whatsapp-server/whatsapp-server-baileys.js
else
    echo "   ⚠️  Función start no encontrada"
    echo "   Mostrando últimas 50 líneas del archivo:"
    tail -50 whatsapp-server/whatsapp-server-baileys.js
fi
echo ""

# 5. Verificar si tiene el código actualizado
echo "4️⃣  Verificando si tiene el código actualizado..."
if grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ El archivo YA tiene el código actualizado"
elif grep -q "await connectToWhatsApp" whatsapp-server/whatsapp-server-baileys.js && grep -q "server.listen" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ⚠️  El archivo tiene el código ANTIGUO (conecta WhatsApp antes del servidor)"
    echo "   Necesitas actualizarlo"
else
    echo "   ⚠️  No se pudo determinar el estado"
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
