#!/bin/bash
echo "=== VERIFICANDO FIX ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Buscar archivo
        FILE=$(docker exec $CONTAINER find /app /root /home -name "whatsapp-server.js" 2>/dev/null | head -1)
        
        if [ ! -z "$FILE" ]; then
            echo "   Archivo encontrado: $FILE"
            echo "   Línea de server.listen:"
            docker exec $CONTAINER grep "server.listen" $FILE | head -1
            
            # Verificar si tiene 0.0.0.0
            if docker exec $CONTAINER grep -q "0.0.0.0" $FILE 2>/dev/null; then
                echo "   ✅ Tiene 0.0.0.0"
            else
                echo "   ❌ NO tiene 0.0.0.0 - Aplicando fix..."
                docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" $FILE
                docker service update --force $s
            fi
        else
            echo "   ⚠️  Archivo no encontrado"
            echo "   Directorio de trabajo:"
            docker exec $CONTAINER pwd 2>/dev/null
            echo "   Archivos en /app:"
            docker exec $CONTAINER ls -la /app 2>/dev/null | head -5
        fi
        
        # Ver logs
        echo "   Últimos logs:"
        docker service logs $s --tail 3 2>&1 | tail -2
    fi
    echo ""
done

echo "⏳ Esperando 30 segundos..."
sleep 30

echo ""
echo "=== PROBANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "   No responde aún"
done
