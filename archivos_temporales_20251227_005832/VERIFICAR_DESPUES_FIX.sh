#!/bin/bash
# Verificar después del fix

echo "=== VERIFICANDO ESTADO DE LOS SERVICIOS ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Ver estado del servicio
    STATUS=$(docker service ps $s --format "{{.CurrentState}}" | head -1)
    echo "   Estado: $STATUS"
    
    # Ver logs recientes
    echo "   Logs recientes (últimas 5 líneas):"
    docker service logs $s --tail 5 2>&1 | tail -5
    
    # Verificar si el proceso está corriendo
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        echo "   Proceso Node.js:"
        docker exec $CONTAINER ps aux 2>/dev/null | grep node | grep -v grep || echo "   ⚠️  No hay proceso node corriendo"
        
        # Probar localhost directamente
        echo "   Probando localhost:$PORT desde el contenedor:"
        docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:$PORT 2>&1 | head -3 || echo "   ❌ No responde en localhost"
    fi
    
    echo ""
done

echo "=== ESPERANDO 30 SEGUNDOS MÁS ==="
sleep 30

echo ""
echo "=== PRUEBA FINAL DE CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ⚠️  No responde"
done






