#!/bin/bash

# Script para crear las 4 instancias de WhatsApp en Evolution API

# Configuración
API_KEY="${EVOLUTION_API_KEY:-checkin24hs-secret-key-2024}"
API_URL="${EVOLUTION_API_URL:-http://localhost:8080}"

echo "🚀 Creando instancias de WhatsApp en Evolution API..."
echo "📡 URL: $API_URL"
echo "🔑 API Key: ${API_KEY:0:20}..."

# Función para crear instancia
crear_instancia() {
    local nombre=$1
    echo ""
    echo "📱 Creando instancia: $nombre"
    
    response=$(curl -s -X POST "$API_URL/instance/create" \
        -H "apikey: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"instanceName\": \"$nombre\", \"qrcode\": true, \"integration\": \"WHATSAPP-BAILEYS\"}")
    
    if echo "$response" | grep -q "instance"; then
        echo "✅ Instancia $nombre creada exitosamente"
    else
        echo "❌ Error creando instancia $nombre: $response"
    fi
}

# Crear las 4 instancias
crear_instancia "whatsapp-1"
crear_instancia "whatsapp-2"
crear_instancia "whatsapp-3"
crear_instancia "whatsapp-4"

echo ""
echo "✅ Proceso completado!"
echo ""
echo "📋 Para obtener los QR codes, ejecuta:"
echo "   curl $API_URL/instance/connect/whatsapp-1 -H \"apikey: $API_KEY\""
echo "   curl $API_URL/instance/connect/whatsapp-2 -H \"apikey: $API_KEY\""
echo "   curl $API_URL/instance/connect/whatsapp-3 -H \"apikey: $API_KEY\""
echo "   curl $API_URL/instance/connect/whatsapp-4 -H \"apikey: $API_KEY\""


