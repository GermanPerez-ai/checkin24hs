#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 DIAGNÓSTICO Y CORRECCIÓN WHATSAPP"
echo "=========================================="
echo ""

# 1. ENCONTRAR CONTENEDORES WHATSAPP
WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))
if [ ${#WHATSAPP_CONTAINERS[@]} -eq 0 ]; then
    echo "❌ No se encontraron contenedores WhatsApp"
    exit 1
fi

echo "📦 Contenedores encontrados: ${#WHATSAPP_CONTAINERS[@]}"
for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "   - $CONTAINER"
done
echo ""

# 2. VERIFICAR CÓDIGO ACTUAL
echo "=========================================="
echo "1️⃣ VERIFICANDO CÓDIGO ACTUAL"
echo "=========================================="
CONTAINER="${WHATSAPP_CONTAINERS[0]}"
echo "Contenedor: $CONTAINER"
echo ""

echo "📋 Función saveMessageToSupabase:"
docker exec "$CONTAINER" grep -A 25 "async function saveMessageToSupabase" /app/whatsapp-server.js | head -30
echo ""

echo "📋 Insert en whatsapp_messages:"
docker exec "$CONTAINER" grep -A 10 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 10 "\.insert"
echo ""

# 3. VERIFICAR CONFIGURACIÓN SUPABASE
echo "=========================================="
echo "2️⃣ VERIFICANDO CONFIGURACIÓN SUPABASE"
echo "=========================================="
echo "📋 Variable SAVE_TO_SUPABASE:"
docker exec "$CONTAINER" grep -i "SAVE_TO_SUPABASE" /app/whatsapp-server.js | head -5
echo ""

echo "📋 Variables de entorno relacionadas con Supabase:"
docker exec "$CONTAINER" env | grep -i "supabase\|save" || echo "   (No se encontraron variables de entorno)"
echo ""

# 4. VER LOGS RECIENTES
echo "=========================================="
echo "3️⃣ ÚLTIMOS LOGS (últimas 30 líneas)"
echo "=========================================="
docker logs "$CONTAINER" --tail 30 2>&1 | grep -E "(Error|error|guardando|Supabase|saveMessage)" || echo "   (No se encontraron logs relevantes)"
echo ""

# 5. CORREGIR CÓDIGO
echo "=========================================="
echo "4️⃣ CORRIGIENDO CÓDIGO"
echo "=========================================="

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔧 Corrigiendo: $CONTAINER"
    
    # Hacer backup
    docker exec "$CONTAINER" cp /app/whatsapp-server.js /app/whatsapp-server.js.backup
    
    # Corregir: cambiar message: por body:
    docker exec "$CONTAINER" sed -i 's/message: message,/body: message || "",/g' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i 's/"message": message/"body": message || ""/g' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i "s/message: message,/body: message || \"\",/g" /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i 's/"message": message/"body": message || ""/g' /app/whatsapp-server.js
    
    # Eliminar campos que no existen
    docker exec "$CONTAINER" sed -i '/phone: cleanPhone,/d' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i '/message_type: messageType,/d' /app/whatsapp-server.js
    docker exec "$CONTAINER" sed -i '/whatsapp_instance: CONFIG.INSTANCE_NUMBER/d' /app/whatsapp-server.js
    
    # Asegurar que tiene created_at
    if ! docker exec "$CONTAINER" grep -A 5 "whatsapp_messages" /app/whatsapp-server.js | grep -q "created_at"; then
        echo "   ⚠️ No se encontró created_at, agregando..."
        docker exec "$CONTAINER" sed -i '/is_read: isFromMe,/a\                created_at: new Date().toISOString()' /app/whatsapp-server.js
    fi
    
    echo "   ✅ Correcciones aplicadas"
done

echo ""

# 6. VERIFICAR CORRECCIÓN
echo "=========================================="
echo "5️⃣ VERIFICANDO CORRECCIÓN"
echo "=========================================="
CONTAINER="${WHATSAPP_CONTAINERS[0]}"
echo "📋 Código después de corrección:"
docker exec "$CONTAINER" grep -A 15 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 10 "\.insert"
echo ""

# 7. REINICIAR CONTENEDORES
echo "=========================================="
echo "6️⃣ REINICIANDO CONTENEDORES"
echo "=========================================="
for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔄 Reiniciando: $CONTAINER"
    docker restart "$CONTAINER"
    sleep 3
done

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Envía un mensaje de prueba desde WhatsApp"
echo "2. Ejecuta este comando para ver logs en tiempo real:"
echo "   docker logs ${WHATSAPP_CONTAINERS[0]} --tail 50 -f"
echo "3. Verifica en Supabase que el mensaje se guardó en la tabla whatsapp_messages"
echo ""
