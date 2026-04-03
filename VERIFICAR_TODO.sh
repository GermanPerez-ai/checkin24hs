#!/bin/bash
echo "=== PROBANDO CONECTIVIDAD DESDE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s (puerto $PORT):"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ❌ No responde"
done

echo ""
echo "=== LOGS DE TRAEFIK (últimas 30 líneas) ==="
docker service logs traefik --tail 30 2>&1

echo ""
echo "=== VERIFICANDO API DE TRAEFIK ==="
docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i whatsapp || echo "No hay routers de WhatsApp"
