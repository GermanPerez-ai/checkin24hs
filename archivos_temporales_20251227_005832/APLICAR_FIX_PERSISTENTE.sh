#!/bin/bash
# Aplicar fix de forma persistente sin reiniciar el servicio completo

echo "=== APLICANDO FIX PERSISTENTE ==="
echo ""

# Esperar a que los servicios estén completamente iniciados
echo "Esperando 40 segundos para que los servicios inicien completamente..."
sleep 40

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar estado actual
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        echo "   Estado actual: $CURRENT"
        
        # Aplicar fix si no está
        if ! echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   Aplicando fix..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
            
            # Verificar que se aplicó
            NEW=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
            if echo "$NEW" | grep -q "0.0.0.0"; then
                echo "   ✅ Fix aplicado: $NEW"
                
                # Reiniciar solo el proceso Node.js (el contenedor se mantiene)
                echo "   Reiniciando proceso Node.js dentro del contenedor..."
                PID=$(docker exec $CONTAINER pgrep -f "node whatsapp-server.js" | head -1)
                if [ ! -z "$PID" ]; then
                    docker exec $CONTAINER kill -HUP $PID 2>/dev/null || docker exec $CONTAINER kill $PID 2>/dev/null
                    echo "   ✅ Proceso reiniciado (Docker Swarm lo reiniciará automáticamente)"
                else
                    echo "   ⚠️  No se encontró proceso Node.js"
                fi
            else
                echo "   ❌ Error al aplicar fix"
            fi
        else
            echo "   ✅ Ya tiene el fix aplicado"
        fi
        
        # Ver logs
        echo "   Logs recientes:"
        docker service logs $s --tail 3 2>&1 | tail -3
    fi
    
    echo ""
done

echo "⏳ Esperando 30 segundos para que los procesos se reinicien..."
sleep 30

echo ""
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "   ⚠️  No responde"
done






