#!/bin/bash
# Verificar y aplicar fix de forma persistente

echo "=== VERIFICANDO Y APLICANDO FIX PERSISTENTE ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar estado actual
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Estado actual: $CURRENT"
        
        # Aplicar fix si no está
        if ! echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   Aplicando fix..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            echo "   ✅ Fix aplicado"
        else
            echo "   ✅ Ya tiene el fix"
        fi
        
        # Ver logs para ver si el servidor está iniciando
        echo "   Logs recientes:"
        docker service logs $s --tail 15 2>&1 | tail -5
        
        # Verificar si el proceso está corriendo
        echo "   Proceso Node.js:"
        docker exec $CONTAINER ps aux 2>/dev/null | grep "node whatsapp" | grep -v grep || echo "   ⚠️  No hay proceso node corriendo"
    fi
    
    echo ""
done

echo "⏳ Esperando 30 segundos más para que los servicios terminen de iniciar..."
sleep 30

echo ""
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "   ⚠️  No responde"
done






