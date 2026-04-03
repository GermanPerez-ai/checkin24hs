#!/bin/bash
# Reiniciar servicios que están detenidos

echo "=== REINICIANDO SERVICIOS DETENIDOS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Ver estado actual
    STATUS=$(docker service ps $s --format "{{.CurrentState}}" | head -1)
    echo "   Estado actual: $STATUS"
    
    # Ver logs recientes para entender por qué se detuvo
    if [ "$STATUS" = "Complete" ] || [ "$STATUS" = "Shutdown" ]; then
        echo "   Logs recientes (últimas 10 líneas):"
        docker service logs $s --tail 10 2>&1 | tail -10
    fi
    
    # Escalar a 1 para reiniciar
    echo "   Reiniciando servicio..."
    docker service scale $s=1
    
    echo ""
done

echo "⏳ Esperando 30 segundos para que los servicios inicien..."
sleep 30

echo ""
echo "=== APLICANDO FIX DESPUÉS DEL REINICIO ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s:"
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Aplicar fix
        docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js 2>/dev/null
        
        # Verificar
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Fix aplicado"
        else
            echo "   ❌ Error al aplicar fix"
        fi
        
        # Reiniciar proceso Node.js
        docker exec $CONTAINER pkill -f "node whatsapp-server.js" 2>/dev/null || true
    else
        echo "   ⚠️  Aún no hay contenedor"
    fi
done

echo ""
echo "⏳ Esperando 40 segundos más..."
sleep 40

echo ""
echo "=== VERIFICANDO ESTADO FINAL ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "$s:"
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
    fi
done


















