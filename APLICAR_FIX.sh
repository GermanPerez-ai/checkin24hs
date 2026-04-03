#!/bin/bash
echo "=== APLICANDO FIX: Servidor debe escuchar en 0.0.0.0 ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "🔧 $s..."
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Buscar el archivo
        if docker exec $CONTAINER test -f /app/whatsapp-server.js 2>/dev/null; then
            FILE="/app/whatsapp-server.js"
        elif docker exec $CONTAINER test -f whatsapp-server.js 2>/dev/null; then
            FILE="whatsapp-server.js"
        else
            echo "   ⚠️  Archivo no encontrado"
            continue
        fi
        
        # Aplicar cambio
        docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" $FILE
        
        echo "   ✅ Fix aplicado"
        echo "   🔄 Reiniciando..."
        docker service update --force $s
        sleep 5
    fi
done

echo ""
echo "⏳ Esperando 30 segundos..."
sleep 30

echo ""
echo "=== VERIFICANDO ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "   Aún no responde"
done
