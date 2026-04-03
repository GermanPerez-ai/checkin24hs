#!/bin/bash
# Verificar logs completos para encontrar el problema

echo "=== VERIFICANDO LOGS COMPLETOS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto esperado: $PORT):"
    
    # Ver primeras 30 líneas de logs (inicio del contenedor)
    echo "   Primeras 30 líneas (inicio):"
    docker service logs $s 2>&1 | head -30
    
    # Ver últimas 20 líneas (estado actual)
    echo "   Últimas 20 líneas (estado actual):"
    docker service logs $s --tail 20 2>&1
    
    # Verificar si el archivo tiene el cambio
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        echo "   Verificando archivo whatsapp-server.js:"
        FILE=$(docker exec $CONTAINER find /app -name "whatsapp-server.js" 2>/dev/null | head -1)
        if [ ! -z "$FILE" ]; then
            echo "   Archivo encontrado: $FILE"
            echo "   Línea de server.listen:"
            docker exec $CONTAINER grep "server.listen" $FILE | head -1
        else
            echo "   ⚠️  Archivo whatsapp-server.js no encontrado"
        fi
    fi
    
    echo ""
    echo "---"
    echo ""
done
