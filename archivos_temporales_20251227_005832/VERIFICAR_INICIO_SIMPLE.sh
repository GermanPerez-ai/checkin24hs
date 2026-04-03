#!/bin/bash
# Verificar inicio del servidor (versión simple)

echo "=== VERIFICANDO INICIO DEL SERVIDOR ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Buscar mensaje de inicio (limitado a 50 líneas)
    docker service logs $s --tail 50 2>&1 | grep -E "Servidor corriendo|running|puerto|port|listen|Servidor WhatsApp" | head -3
    
    # Verificar si el archivo tiene el cambio
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        FILE=$(docker exec $CONTAINER find /app -name "whatsapp-server.js" 2>/dev/null | head -1)
        if [ ! -z "$FILE" ]; then
            echo "   Verificando archivo:"
            docker exec $CONTAINER grep "server.listen" $FILE | head -1
        fi
    fi
    
    echo ""
done






