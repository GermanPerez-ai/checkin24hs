#!/bin/bash
# Aplicar fix a whatsapp1 y whatsapp2

echo "=== APLICANDO FIX A WHATSAPP1 Y WHATSAPP2 ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Aplicar fix
        echo "   Aplicando fix..."
        docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
        
        # Verificar
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Fix aplicado: $CURRENT"
        else
            echo "   ❌ Error al aplicar fix"
        fi
        
        # Reiniciar escalando
        echo "   Reiniciando servicio..."
        docker service scale $s=0
        sleep 3
        docker service scale $s=1
        echo "   ✅ Servicio reiniciado"
    fi
    
    echo ""
done

echo "⏳ Esperando 40 segundos para que los servicios inicien..."
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






