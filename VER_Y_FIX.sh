#!/bin/bash
echo "=== VERIFICANDO Y APLICANDO FIX ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar estado
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Estado: $CURRENT"
        
        # Aplicar fix si no está
        if ! echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   Aplicando fix..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            echo "   ✅ Fix aplicado"
            
            # Reiniciar solo el proceso Node.js dentro del contenedor
            echo "   Reiniciando proceso Node.js..."
            docker exec $CONTAINER pkill -f "node whatsapp-server.js" || true
            sleep 2
        else
            echo "   ✅ Ya tiene el fix"
        fi
        
        # Ver logs
        echo "   Logs:"
        docker service logs $s --tail 5 2>&1 | tail -3
    fi
    echo ""
done

echo "Esperando 20 segundos..."
sleep 20

echo ""
echo "=== VERIFICANDO ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde"
done
