#!/bin/bash
# Solución final simple

echo "=== APLICANDO FIX A TODOS LOS SERVICIOS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ -z "$CONTAINER" ]; then
        echo "   ⚠️  No se encontró contenedor activo"
        echo ""
        continue
    fi
    
    # Aplicar fix
    echo "   Aplicando fix..."
    docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js 2>/dev/null
    
    # Verificar
    CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
    if echo "$CURRENT" | grep -q "0.0.0.0"; then
        echo "   ✅ Fix aplicado"
    else
        echo "   ❌ Error al aplicar fix"
    fi
    
    # Reiniciar proceso
    echo "   Reiniciando proceso Node.js..."
    docker exec $CONTAINER pkill -f "node whatsapp-server.js" 2>/dev/null || true
    
    echo ""
done

echo "⏳ Esperando 50 segundos para que los procesos se reinicien..."
sleep 50

echo ""
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "⚠️  No se encontró contenedor de Traefik"
    exit 1
fi

EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

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
        echo "   ⚠️  No se pudo verificar"
    fi
done






