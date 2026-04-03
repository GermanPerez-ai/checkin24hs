#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO QR EN EL SERVIDOR"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 1. Ver logs recientes relacionados con QR
echo "1️⃣ Logs relacionados con QR (últimas 100 líneas):"
echo "=========================================="
docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "qr\|QR\|escanea\|código" | tail -20
echo ""

# 2. Probar el endpoint del QR directamente
echo "2️⃣ Probando endpoint /api/qr:"
echo "=========================================="
curl -s https://api1.checkin24hs.com/api/qr?card=1 | python3 -m json.tool 2>/dev/null || curl -s https://api1.checkin24hs.com/api/qr?card=1
echo ""
echo ""

# 3. Verificar el código que maneja el QR
echo "3️⃣ Verificando código que maneja QR:"
echo "=========================================="
docker exec "$CONTAINER" grep -n "qrCodeData = qr" /app/whatsapp-server.js 2>/dev/null
docker exec "$CONTAINER" grep -n "qr: qrCodeData" /app/whatsapp-server.js 2>/dev/null
echo ""

# 4. Ver logs en tiempo real mientras se genera un nuevo QR
echo "4️⃣ Para ver logs en tiempo real mientras se genera QR:"
echo "=========================================="
echo "Ejecuta esto y luego haz clic en 'Conectar' en el dashboard:"
echo ""
echo "  docker logs \"$CONTAINER\" -f | grep -i \"qr\|escanea\""
echo ""



