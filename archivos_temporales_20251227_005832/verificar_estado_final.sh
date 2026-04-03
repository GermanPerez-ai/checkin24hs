#!/bin/bash
# Verificar estado final de los servicios

echo "=== VERIFICANDO ESTADO FINAL ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Verificar estado del servicio
    STATUS=$(docker service ps $s --format "{{.CurrentState}}" | head -1)
    echo "   Estado: $STATUS"
    
    # Verificar si tiene el fix
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Tiene fix de 0.0.0.0"
        else
            echo "   ❌ NO tiene fix - Aplicando..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            docker service scale $s=0
            sleep 3
            docker service scale $s=1
        fi
        
        # Ver logs recientes
        echo "   Logs recientes:"
        docker service logs $s --tail 5 2>&1 | grep -E "Servidor corriendo|running|puerto|port|Error|error" | head -2 || echo "   Sin mensajes relevantes"
    fi
    
    echo ""
done

echo "⏳ Esperando 20 segundos más..."
sleep 20

echo ""
echo "=== VERIFICANDO CONECTIVIDAD FINAL ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde"
done






