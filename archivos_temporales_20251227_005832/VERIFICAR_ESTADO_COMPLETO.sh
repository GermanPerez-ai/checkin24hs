#!/bin/bash
# Verificar estado completo de todos los servicios

echo "=== ESTADO DE LOS SERVICIOS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Ver estado del servicio
    STATUS=$(docker service ps $s --format "{{.CurrentState}}" | head -1)
    echo "   Estado servicio: $STATUS"
    
    # Ver contenedor
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ -z "$CONTAINER" ]; then
        echo "   ⚠️  No hay contenedor activo"
        echo ""
        continue
    fi
    
    echo "   Contenedor: $CONTAINER"
    
    # Verificar fix
    CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
    if echo "$CURRENT" | grep -q "0.0.0.0"; then
        echo "   ✅ Tiene fix de 0.0.0.0"
    else
        echo "   ❌ NO tiene fix: $CURRENT"
    fi
    
    # Ver puertos escuchando
    echo "   Puertos escuchando:"
    docker exec $CONTAINER netstat -tuln 2>/dev/null | grep LISTEN | head -3 || docker exec $CONTAINER ss -tuln 2>/dev/null | grep LISTEN | head -3 || echo "   No se pudo verificar"
    
    echo ""
done

echo "=== VERIFICANDO CONECTIVIDAD DESDE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "⚠️  No se encontró contenedor de Traefik"
    exit 1
fi

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ] && [ ! -z "$EASYPANEL_NET" ]; then
        CONTAINER_IP=$(docker inspect $CONTAINER --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}" 2>/dev/null)
        
        if [ ! -z "$CONTAINER_IP" ] && [ "$CONTAINER_IP" != "<no value>" ]; then
            echo "   IP: $CONTAINER_IP"
            docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://$CONTAINER_IP:$PORT 2>&1 | head -2 || echo "   ⚠️  No responde"
        else
            echo "   ⚠️  No se pudo obtener IP"
        fi
    else
        echo "   ⚠️  No se pudo verificar (contenedor o red no encontrados)"
    fi
done






