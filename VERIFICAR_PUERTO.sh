#!/bin/bash
echo "=== BUSCANDO MENSAJE DE INICIO ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service logs $s 2>&1 | grep -E "Servidor corriendo|running on|puerto|port|PORT" | head -3
done

echo ""
echo "=== PROBANDO PUERTOS ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp4" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Puerto 80:"
    docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:80 2>&1 | head -5 || echo "No responde"
    echo ""
    echo "Puerto 3004:"
    docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:3004 2>&1 | head -5 || echo "No responde"
fi
