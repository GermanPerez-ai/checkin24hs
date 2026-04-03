#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICACIÓN FINAL DEL CÓDIGO"
echo "=========================================="
echo ""

WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "📦 Contenedor: $CONTAINER"
    echo ""
    
    echo "📋 Código de insert en whatsapp_messages:"
    docker exec "$CONTAINER" grep -A 10 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 8 "\.insert"
    echo ""
    
    echo "📋 Verificando campos requeridos:"
    CODE=$(docker exec "$CONTAINER" grep -A 10 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 8 "\.insert")
    
    if echo "$CODE" | grep -q "body:"; then
        echo "   ✅ body: presente"
    else
        echo "   ❌ body: FALTA"
    fi
    
    if echo "$CODE" | grep -q "is_from_me:"; then
        echo "   ✅ is_from_me: presente"
    else
        echo "   ❌ is_from_me: FALTA"
    fi
    
    if echo "$CODE" | grep -q "is_read:"; then
        echo "   ✅ is_read: presente"
    else
        echo "   ❌ is_read: FALTA"
    fi
    
    if echo "$CODE" | grep -q "created_at:"; then
        echo "   ✅ created_at: presente"
    else
        echo "   ❌ created_at: FALTA"
    fi
    
    if echo "$CODE" | grep -q "chat_id:"; then
        echo "   ✅ chat_id: presente"
    else
        echo "   ❌ chat_id: FALTA"
    fi
    
    echo ""
    echo "📋 Verificando campos que NO deben estar:"
    if echo "$CODE" | grep -q "phone:"; then
        echo "   ⚠️ phone: PRESENTE (debe eliminarse)"
    else
        echo "   ✅ phone: no presente (correcto)"
    fi
    
    if echo "$CODE" | grep -q "message:"; then
        echo "   ⚠️ message: PRESENTE (debe ser body)"
    else
        echo "   ✅ message: no presente (correcto)"
    fi
    
    if echo "$CODE" | grep -q "message_type:"; then
        echo "   ⚠️ message_type: PRESENTE (debe eliminarse)"
    else
        echo "   ✅ message_type: no presente (correcto)"
    fi
    
    if echo "$CODE" | grep -q "whatsapp_instance:"; then
        echo "   ⚠️ whatsapp_instance: PRESENTE (debe eliminarse)"
    else
        echo "   ✅ whatsapp_instance: no presente (correcto)"
    fi
    
    echo ""
    echo "----------------------------------------"
    echo ""
done

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETA"
echo "=========================================="
