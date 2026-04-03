#!/bin/bash
echo "=== VERIFICANDO SI ESTÁN ESCUCHANDO ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Ver puertos escuchando
        echo "   Puertos escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep ":$PORT " || docker exec $CONTAINER ss -tuln 2>/dev/null | grep ":$PORT " || echo "   ⚠️  No escucha en puerto $PORT"
        
        # Ver logs completos de inicio
        echo "   Logs completos (últimas 20 líneas):"
        docker service logs $s --tail 20 2>&1 | tail -20
    fi
    echo ""
done
