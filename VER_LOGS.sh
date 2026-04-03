#!/bin/bash
echo "=== LOGS COMPLETOS ==="
echo ""

for s in checkin24hs_whatsapp1; do
    echo "📋 $s:"
    echo "Primeras 40 líneas:"
    docker service logs $s 2>&1 | head -40
    echo ""
    echo "Últimas 20 líneas:"
    docker service logs $s --tail 20 2>&1
    echo ""
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        FILE=$(docker exec $CONTAINER find /app -name "whatsapp-server.js" 2>/dev/null | head -1)
        if [ ! -z "$FILE" ]; then
            echo "Archivo: $FILE"
            echo "Línea server.listen:"
            docker exec $CONTAINER grep "server.listen" $FILE | head -1
        fi
    fi
done
