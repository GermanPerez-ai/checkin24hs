#!/bin/bash
echo "=== LOGS COMPLETOS WHATSAPP4 (últimas 50 líneas) ==="
docker service logs checkin24hs_whatsapp4 --tail 50 2>&1
echo ""

echo "=== VERIFICANDO PROCESOS ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp4" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Procesos en whatsapp4:"
    docker exec $CONTAINER ps aux 2>/dev/null | head -10
    echo ""
    echo "Probando conexión localhost:3004:"
    docker exec $CONTAINER wget -qO- --timeout=3 http://localhost:3004 2>&1 | head -10 || echo "No responde"
fi
