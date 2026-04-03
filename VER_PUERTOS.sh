#!/bin/bash
echo "=== VERIFICANDO PUERTOS Y LOGS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (esperado: $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Ver puertos escuchando
        echo "   Puertos escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN
        
        # Buscar mensaje de inicio
        echo "   Mensaje de inicio:"
        docker service logs $s --tail 50 2>&1 | grep -E "Servidor corriendo|running|puerto|port|📡" | head -2
    fi
    echo ""
done
