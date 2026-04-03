#!/bin/bash
echo "=== REINICIANDO SERVICIOS ESCALANDO ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 Reiniciando $s (puerto $PORT):"
    
    # Escalar a 0 (detener)
    echo "   Deteniendo..."
    docker service scale $s=0
    sleep 5
    
    # Escalar a 1 (iniciar)
    echo "   Iniciando..."
    docker service scale $s=1
    sleep 10
    
    echo "   ✅ $s reiniciado"
    echo ""
done

echo "⏳ Esperando 30 segundos..."
sleep 30

echo ""
echo "=== VERIFICANDO ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "No responde aún"
done
