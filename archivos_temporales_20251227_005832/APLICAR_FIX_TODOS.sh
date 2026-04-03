#!/bin/bash
# Aplicar fix a todos los servicios de WhatsApp

echo "=== APLICANDO FIX A TODOS LOS SERVICIOS ==="
echo ""

# Esperar a que los servicios estén iniciados
echo "Esperando 30 segundos para que los servicios inicien..."
sleep 30

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar estado actual
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Estado: $CURRENT"
        
        # Aplicar fix si no está
        if ! echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   Aplicando fix..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            
            # Verificar
            NEW=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
            if echo "$NEW" | grep -q "0.0.0.0"; then
                echo "   ✅ Fix aplicado"
                
                # Reiniciar proceso Node.js
                echo "   Reiniciando proceso Node.js..."
                docker exec $CONTAINER pkill -f "node whatsapp-server.js" || true
            else
                echo "   ❌ Error al aplicar fix"
            fi
        else
            echo "   ✅ Ya tiene el fix"
        fi
    else
        echo "   ⚠️  No se encontró contenedor"
    fi
    
    echo ""
done

echo "⏳ Esperando 40 segundos para que los procesos se reinicien..."
sleep 40

echo ""
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ] && [ ! -z "$TRAEFIK_CONTAINER" ] && [ ! -z "$EASYPANEL_NET" ]; then
        # Obtener IP del contenedor
        CONTAINER_IP=$(docker inspect $CONTAINER --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}")
        
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






