#!/bin/bash
echo "=== VERIFICANDO DIRECTAMENTE ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar fix
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Tiene fix"
        else
            echo "   ❌ NO tiene fix"
        fi
        
        # Ver puertos escuchando
        echo "   Escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep ":$PORT " || docker exec $CONTAINER ss -tuln 2>/dev/null | grep ":$PORT " || echo "   No escucha"
        
        # Probar localhost
        echo "   Probando localhost:"
        docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:$PORT 2>&1 | head -1 || echo "   No responde"
        
        # Obtener IP y probar desde Traefik
        EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')
        if [ ! -z "$EASYPANEL_NET" ]; then
            CONTAINER_IP=$(docker inspect $CONTAINER --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}")
            if [ ! -z "$CONTAINER_IP" ] && [ "$CONTAINER_IP" != "<no value>" ]; then
                echo "   IP: $CONTAINER_IP"
                TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
                if [ ! -z "$TRAEFIK_CONTAINER" ]; then
                    echo "   Probando desde Traefik:"
                    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://$CONTAINER_IP:$PORT 2>&1 | head -2 || echo "   No responde"
                fi
            fi
        fi
    fi
    echo ""
done
