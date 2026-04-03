#!/bin/bash
# Verificar si el fix se aplicó correctamente

echo "=== VERIFICANDO SI EL FIX SE APLICÓ ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Buscar el archivo
        if docker exec $CONTAINER test -f /app/whatsapp-server.js 2>/dev/null; then
            FILE="/app/whatsapp-server.js"
        elif docker exec $CONTAINER test -f whatsapp-server.js 2>/dev/null; then
            FILE="whatsapp-server.js"
        else
            # Buscar en el directorio de trabajo
            WORKDIR=$(docker exec $CONTAINER pwd 2>/dev/null)
            echo "   Directorio de trabajo: $WORKDIR"
            docker exec $CONTAINER find . -name "whatsapp-server.js" 2>/dev/null | head -3
            continue
        fi
        
        # Verificar la línea del listen
        echo "   Verificando línea de server.listen:"
        docker exec $CONTAINER grep "server.listen" $FILE | head -1
        
        # Verificar si escucha en 0.0.0.0
        if docker exec $CONTAINER grep -q "server.listen(CONFIG.PORT, '0.0.0.0'" $FILE 2>/dev/null; then
            echo "   ✅ Está configurado para escuchar en 0.0.0.0"
        else
            echo "   ❌ NO está configurado para escuchar en 0.0.0.0"
            echo "   Aplicando fix de nuevo..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" $FILE
            docker service update --force $s
        fi
        
        # Ver logs recientes
        echo "   Logs recientes:"
        docker service logs $s --tail 5 2>&1 | grep -E "puerto|port|running|listen" | head -2
    fi
    
    echo ""
done

echo "=== ESPERANDO 20 SEGUNDOS MÁS ==="
sleep 20

echo ""
echo "=== PROBANDO CONECTIVIDAD DE NUEVO ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ⚠️  Aún no responde"
done






