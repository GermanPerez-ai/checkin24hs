#!/bin/bash
# Aplicar fix sin reiniciar el proceso

echo "=== APLICANDO FIX SIN REINICIAR ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Esperar a que el servicio esté completamente iniciado
        echo "   Esperando a que el servicio inicie completamente..."
        sleep 10
        
        # Verificar estado
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
                echo "   ⚠️  El servidor necesita reiniciarse para aplicar el cambio"
                echo "   Reiniciando servicio completo..."
                docker service update --force $s
            else
                echo "   ❌ Error al aplicar fix"
            fi
        else
            echo "   ✅ Ya tiene el fix aplicado"
        fi
        
        # Ver logs recientes
        echo "   Logs recientes:"
        docker service logs $s --tail 3 2>&1 | tail -3
    fi
    
    echo ""
done

echo "⏳ Esperando 40 segundos para que los servicios se reinicien..."
sleep 40

echo ""
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "   ⚠️  No responde"
done
