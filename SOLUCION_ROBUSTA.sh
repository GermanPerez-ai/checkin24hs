#!/bin/bash
echo "=== SOLUCIÓN ROBUSTA ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "🔧 $s:"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Buscar archivo
        FILE=$(docker exec $CONTAINER sh -c "find /app /root /home -name 'whatsapp-server.js' 2>/dev/null" | head -1)
        
        if [ -z "$FILE" ]; then
            WORKDIR=$(docker exec $CONTAINER pwd 2>/dev/null)
            if docker exec $CONTAINER test -f "$WORKDIR/whatsapp-server.js" 2>/dev/null; then
                FILE="$WORKDIR/whatsapp-server.js"
            fi
        fi
        
        if [ ! -z "$FILE" ]; then
            echo "   Archivo: $FILE"
            
            # Ver línea actual
            docker exec $CONTAINER grep "server.listen" $FILE | head -1
            
            # Aplicar cambio con múltiples patrones
            docker exec $CONTAINER sh -c "
                sed -i \"s/server\.listen(CONFIG\.PORT,/server.listen(CONFIG.PORT, '0.0.0.0',/g\" $FILE
            "
            
            # Verificar
            NEW=$(docker exec $CONTAINER grep "server.listen" $FILE | head -1)
            echo "   Nueva: $NEW"
            
            if echo "$NEW" | grep -q "0.0.0.0"; then
                echo "   ✅ OK"
            else
                echo "   ⚠️  No se aplicó, mostrando contexto:"
                docker exec $CONTAINER grep -A 2 -B 2 "server.listen" $FILE | head -5
            fi
            
            docker service update --force $s
        else
            echo "   ⚠️  Archivo no encontrado"
        fi
    fi
    echo ""
done

echo "⏳ Esperando 40 segundos..."
sleep 40

echo ""
echo "=== PRUEBA FINAL ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde"
done
