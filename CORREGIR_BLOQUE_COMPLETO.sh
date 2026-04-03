#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRECCIÓN COMPLETA DEL BLOQUE INSERT"
echo "=========================================="
echo ""

WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔧 Corrigiendo: $CONTAINER"
    
    # Hacer backup
    docker exec "$CONTAINER" cp /app/whatsapp-server.js /app/whatsapp-server.js.backup.$(date +%s)
    
    # Crear archivo temporal con el código correcto
    docker exec "$CONTAINER" bash -c 'cat > /tmp/correct_insert.txt << "CORRECT"
            .insert([{
                chat_id: chat?.id || null,
                body: message || "",
                is_from_me: isFromMe,
                is_read: isFromMe,
                created_at: new Date().toISOString()
            }])
CORRECT
'
    
    # Encontrar la línea donde empieza el insert
    LINE_START=$(docker exec "$CONTAINER" grep -n "\.insert(\[" /app/whatsapp-server.js | grep "whatsapp_messages" | head -1 | cut -d: -f1)
    
    if [ -z "$LINE_START" ]; then
        echo "   ⚠️ No se encontró la línea de insert, buscando alternativa..."
        LINE_START=$(docker exec "$CONTAINER" grep -n "\.insert(\[" /app/whatsapp-server.js | head -1 | cut -d: -f1)
    fi
    
    if [ -z "$LINE_START" ]; then
        echo "   ❌ No se pudo encontrar el bloque insert"
        continue
    fi
    
    # Encontrar la línea donde termina el bloque (buscar la línea con }])
    LINE_END=$(docker exec "$CONTAINER" sed -n "${LINE_START},${LINE_START}+10p" /app/whatsapp-server.js | grep -n "}\]" | head -1 | cut -d: -f1)
    LINE_END=$((LINE_START + LINE_END - 1))
    
    if [ -z "$LINE_END" ] || [ "$LINE_END" -lt "$LINE_START" ]; then
        echo "   ⚠️ No se encontró el final del bloque, usando método alternativo..."
        # Método alternativo: eliminar líneas y agregar el código correcto
        docker exec "$CONTAINER" sed -i "${LINE_START},${LINE_START}+7d" /app/whatsapp-server.js
        docker exec "$CONTAINER" sed -i "${LINE_START}i\            .insert([{\n                chat_id: chat?.id || null,\n                body: message || \"\",\n                is_from_me: isFromMe,\n                is_read: isFromMe,\n                created_at: new Date().toISOString()\n            }])" /app/whatsapp-server.js
    else
        # Eliminar el bloque viejo
        docker exec "$CONTAINER" sed -i "${LINE_START},${LINE_END}d" /app/whatsapp-server.js
        
        # Insertar el código correcto
        docker exec "$CONTAINER" bash -c "sed -i '${LINE_START}i\            .insert([{\n                chat_id: chat?.id || null,\n                body: message || \"\",\n                is_from_me: isFromMe,\n                is_read: isFromMe,\n                created_at: new Date().toISOString()\n            }])' /app/whatsapp-server.js"
    fi
    
    echo "   ✅ Corrección aplicada"
    
    # Verificar
    echo "   📋 Código después de corrección:"
    docker exec "$CONTAINER" grep -A 8 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 6 "\.insert" | head -8
    echo ""
done

echo "=========================================="
echo "🔄 REINICIANDO CONTENEDORES"
echo "=========================================="

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔄 Reiniciando: $CONTAINER"
    docker restart "$CONTAINER"
    sleep 3
done

echo ""
echo "✅ Proceso completado"






