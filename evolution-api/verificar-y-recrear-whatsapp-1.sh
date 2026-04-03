#!/bin/bash

cd /root/checkin24hs/evolution-api

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8081"

echo "🔍 VERIFICANDO INSTANCIA whatsapp-1"
echo "====================================="
echo ""

# 1. Verificar todas las instancias
echo "1️⃣  Verificando instancias existentes..."
echo ""

ALL_INSTANCES=$(curl -s -X GET ${BASE_URL}/instance/fetchInstances \
  -H "apikey: ${API_KEY}" \
  2>/dev/null)

if echo "$ALL_INSTANCES" | grep -q "whatsapp-1"; then
    echo "   ✅ whatsapp-1 EXISTE en Evolution API"
    echo ""
    echo "   📋 Información de whatsapp-1:"
    echo "$ALL_INSTANCES" | grep -A 10 "whatsapp-1" | head -10
else
    echo "   ❌ whatsapp-1 NO existe en Evolution API"
    echo ""
    
    echo "   📋 Instancias existentes:"
    echo "$ALL_INSTANCES" | grep -o '"instanceName":"[^"]*"' | sed 's/"instanceName":"//g' | sed 's/"//g' | sed 's/^/      - /'
    echo ""
    
    echo "2️⃣  Recreando instancia whatsapp-1..."
    echo ""
    
    RESPONSE=$(curl -s -X POST ${BASE_URL}/instance/create \
      -H "apikey: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"instanceName\": \"whatsapp-1\",
        \"qrcode\": true,
        \"integration\": \"WHATSAPP-BAILEYS\"
      }")
    
    if echo "$RESPONSE" | grep -q "error\|403\|already in use"; then
        echo "   ⚠️  Error al crear whatsapp-1:"
        echo "$RESPONSE" | head -5
        echo ""
        
        if echo "$RESPONSE" | grep -q "already in use"; then
            echo "   ℹ️  La instancia ya existe, pero puede no estar visible en el panel"
            echo "   🔄 Intentando reconectar..."
            echo ""
            
            # Intentar obtener QR para reconectar
            QR_RESPONSE=$(curl -s -X GET ${BASE_URL}/instance/connect/whatsapp-1 \
              -H "apikey: ${API_KEY}" 2>/dev/null)
            
            if echo "$QR_RESPONSE" | grep -q "qrcode\|base64"; then
                echo "   ✅ Instancia whatsapp-1 reconectada"
            else
                echo "   ⚠️  No se pudo obtener QR, pero la instancia existe"
            fi
        fi
    else
        echo "   ✅ Instancia whatsapp-1 creada exitosamente"
        echo ""
        echo "   📋 Respuesta:"
        echo "$RESPONSE" | head -10
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VERIFICACIÓN COMPLETA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Instancias actuales:"
curl -s -X GET ${BASE_URL}/instance/fetchInstances \
  -H "apikey: ${API_KEY}" 2>/dev/null | \
  grep -o '"instanceName":"[^"]*"' | \
  sed 's/"instanceName":"//g' | \
  sed 's/"//g' | \
  nl -w2 -s'. '
echo ""
echo "✅ Si whatsapp-1 no aparece, refresca el panel web:"
echo "   http://72.61.58.240:8081/manager"
echo ""
echo "🔄 O recarga la página presionando F5"
echo ""
