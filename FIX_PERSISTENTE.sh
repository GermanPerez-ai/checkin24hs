#!/bin/bash
echo "=== APLICANDO FIX PERSISTENTE ==="
echo ""

echo "Esperando 40 segundos para que los servicios inicien..."
sleep 40

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar y aplicar fix
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Estado: $CURRENT"
        
        if ! echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   Aplicando fix..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            echo "   ✅ Fix aplicado"
            
            # Matar proceso Node.js para que Docker Swarm lo reinicie en el mismo contenedor
            echo "   Reiniciando proceso Node.js..."
            docker exec $CONTAINER pkill -f "node whatsapp-server.js" || true
        else
            echo "   ✅ Ya tiene el fix"
        fi
    fi
    echo ""
done

echo "Esperando 30 segundos para que Docker Swarm reinicie los procesos..."
sleep 30

echo ""
echo "=== VERIFICANDO ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde"
done
