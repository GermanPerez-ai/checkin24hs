#!/bin/bash
echo "=== ESTADO DE SERVICIOS ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s (puerto $PORT):"
    STATUS=$(docker service ps $s --format "{{.CurrentState}}" | head -1)
    echo "   Estado: $STATUS"
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Tiene fix"
        else
            echo "   ❌ NO tiene fix"
        fi
    else
        echo "   ⚠️  Sin contenedor"
    fi
done

echo ""
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ] && [ ! -z "$EASYPANEL_NET" ]; then
        CONTAINER_IP=$(docker inspect $CONTAINER --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}" 2>/dev/null)
        if [ ! -z "$CONTAINER_IP" ] && [ "$CONTAINER_IP" != "<no value>" ]; then
            echo "$s (IP: $CONTAINER_IP):"
            docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://$CONTAINER_IP:$PORT 2>&1 | head -2 || echo "   No responde"
        fi
    fi
done
