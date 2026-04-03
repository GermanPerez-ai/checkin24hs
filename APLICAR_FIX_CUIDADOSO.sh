#!/bin/bash
echo "=== APLICANDO FIX CUIDADOSO ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s:"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar estado actual
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Estado actual: $CURRENT"
        
        # Aplicar cambio si no está aplicado
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Ya tiene el cambio"
        else
            echo "   Aplicando fix..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            
            # Verificar
            NEW=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
            if echo "$NEW" | grep -q "0.0.0.0"; then
                echo "   ✅ Fix aplicado"
            else
                echo "   ❌ Error al aplicar"
            fi
        fi
    fi
    echo ""
done

echo "⏳ Esperando 10 segundos..."
sleep 10

echo ""
echo "=== REINICIANDO SERVICIOS UNO POR UNO ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "Reiniciando $s..."
    docker service update --force $s
    echo "Esperando 15 segundos antes del siguiente..."
    sleep 15
done

echo ""
echo "⏳ Esperando 30 segundos más..."
sleep 30

echo ""
echo "=== VERIFICANDO ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde aún"
done
