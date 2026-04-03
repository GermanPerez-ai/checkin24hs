#!/bin/bash
# Crear las 4 instancias WhatsApp en Evolution API

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8081"

echo "📱 Creando instancias WhatsApp en Evolution API..."
echo ""

for i in 1 2 3 4; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 Creando instancia whatsapp-${i}..."
    echo ""
    
    RESPONSE=$(curl -s -X POST ${BASE_URL}/instance/create \
      -H "apikey: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"instanceName\": \"whatsapp-${i}\",
        \"qrcode\": true,
        \"integration\": \"WHATSAPP-BAILEYS\"
      }")
    
    echo "$RESPONSE" | head -10
    echo ""
    
    sleep 1
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Proceso completado"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo ""
echo "   1. Abre el panel web:"
echo "      http://72.61.58.240:8081/manager"
echo ""
echo "   2. Verás las 4 instancias con sus QR codes"
echo ""
echo "   3. Escanea cada QR code con WhatsApp"
echo ""
echo "   4. Para ver estado de las instancias:"
echo "      curl -s http://localhost:8081/instance/fetchInstances -H \"apikey: ${API_KEY}\" | head -50"
echo ""
