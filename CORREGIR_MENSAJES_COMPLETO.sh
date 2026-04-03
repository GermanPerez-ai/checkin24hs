#!/bin/bash

cd /root/checkin24hs

echo "🔧 CORRECCIÓN COMPLETA DE MENSAJES DE WHATSAPP"
echo "================================================"
echo ""

# 1. CORREGIR WHATSAPP SERVER
echo "📱 1. Corrigiendo whatsapp-server.js..."
WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "  🔧 Contenedor: $CONTAINER"
    
    # Backup
    BACKUP_FILE="/app/whatsapp-server.js.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$CONTAINER" cp /app/whatsapp-server.js "$BACKUP_FILE" 2>/dev/null || true
    
    # Corregir: cambiar 'message:' por 'body:'
    echo "    ✅ Cambiando 'message:' a 'body:'..."
    docker exec "$CONTAINER" sed -i 's/message: message,/body: message || "",/g' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i 's/"message": message/"body": message || ""/g' /app/whatsapp-server.js
    
    # Eliminar campos que no existen
    echo "    ✅ Eliminando campos inexistentes..."
    docker exec "$CONTAINER" sed -i '/phone: cleanPhone,/d' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i '/message_type: messageType,/d' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i '/whatsapp_instance: CONFIG.INSTANCE_NUMBER/d' /app/whatsapp-server.js
    
    # Verificar que tiene created_at
    if ! docker exec "$CONTAINER" grep -q "created_at:" /app/whatsapp-server.js | grep -A 3 "whatsapp_messages"; then
        echo "    ✅ Agregando created_at..."
        docker exec "$CONTAINER" sed -i '/is_read: isFromMe,/a\                created_at: new Date().toISOString()' /app/whatsapp-server.js
    fi
    
    # Verificar corrección
    if docker exec "$CONTAINER" grep -q "body: message" /app/whatsapp-server.js; then
        echo "    ✅ Código corregido correctamente"
    else
        echo "    ❌ ERROR: No se encontró 'body'"
    fi
    
    # Reiniciar
    echo "    🔄 Reiniciando contenedor..."
    docker restart "$CONTAINER"
    sleep 3
done

echo ""
echo "📋 2. Corrigiendo dashboard.html..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "  ❌ No se encontró contenedor del dashboard"
else
    echo "  🔧 Contenedor: $DASHBOARD_CONTAINER"
    
    # Backup
    BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$DASHBOARD_CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
    
    # Buscar y corregir cualquier select con from_me
    echo "    ✅ Buscando y corrigiendo 'from_me' en selects..."
    
    # Corregir select('id, chat_id, body, created_at, from_me')
    docker exec "$DASHBOARD_CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
    docker exec "$DASHBOARD_CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
    
    # Corregir .select('id, chat_id, body, created_at, from_me')
    docker exec "$DASHBOARD_CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
    docker exec "$DASHBOARD_CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
    
    # Verificar que no queden from_me incorrectos
    REMAINING=$(docker exec "$DASHBOARD_CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
    
    if [ "$REMAINING" -eq 0 ]; then
        echo "    ✅ No quedan 'from_me' incorrectos"
    else
        echo "    ⚠️ Aún quedan $REMAINING ocurrencias de 'from_me' incorrectas"
        docker exec "$DASHBOARD_CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
    fi
    
    # Reiniciar
    echo "    🔄 Reiniciando dashboard..."
    docker restart "$DASHBOARD_CONTAINER"
    sleep 5
fi

echo ""
echo "✅ CORRECCIÓN COMPLETA"
echo ""
echo "📋 Próximos pasos:"
echo "1. Envía un mensaje de prueba desde WhatsApp"
echo "2. Verifica en Supabase que el mensaje se guardó en whatsapp_messages"
echo "3. Recarga el dashboard con Ctrl+Shift+R y verifica que los mensajes se muestran"
echo ""


