#!/bin/bash
# Verificar si los servicios están escuchando en los puertos

echo "=== VERIFICANDO PUERTOS ESCUCHANDO ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar puertos escuchando
        echo "   Puertos en LISTEN:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN || echo "   No se pudo verificar (comando no disponible)"
        
        # Verificar el archivo tiene el cambio
        FILE=$(docker exec $CONTAINER find /app -name "whatsapp-server.js" 2>/dev/null | head -1)
        if [ ! -z "$FILE" ]; then
            echo "   Verificando cambio en archivo:"
            docker exec $CONTAINER grep "server.listen" $FILE | head -1
        fi
        
        # Ver logs más recientes
        echo "   Últimos logs (últimas 10 líneas):"
        docker service logs $s --tail 10 2>&1 | tail -10
        
        # Intentar conectar con curl si está disponible
        echo "   Probando con curl:"
        docker exec $CONTAINER curl -sI --max-time 3 http://localhost:$PORT 2>&1 | head -3 || docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:$PORT 2>&1 | head -3 || echo "   No responde"
    fi
    
    echo ""
done

echo "=== VERIFICANDO DESDE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "No responde"
done






