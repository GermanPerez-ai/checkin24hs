#!/bin/bash
echo "=== VERIFICANDO ESTADO ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        # Verificar fix
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Línea: $CURRENT"
        
        # Ver logs
        echo "   Logs:"
        docker service logs $s --tail 10 2>&1 | grep -E "Servidor|puerto|running|Error" | head -3
    fi
    echo ""
done

echo "Esperando 20 segundos más..."
sleep 20

echo ""
echo "=== PRUEBA FINAL ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde"
done
