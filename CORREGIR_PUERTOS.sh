#!/bin/bash
echo "=== VERIFICANDO PUERTOS ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "$s:"
    docker service inspect $s --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.PublishMode}}){{println}}{{end}}' 2>/dev/null
done

echo ""
echo "=== ELIMINANDO PUERTOS PUBLICADOS (Traefik se conecta por red) ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "Eliminando puertos de $s..."
    docker service update --publish-rm 3001:3001 $s 2>/dev/null
    docker service update --publish-rm 3002:3002 $s 2>/dev/null
    docker service update --publish-rm 3003:3003 $s 2>/dev/null
    docker service update --publish-rm 3004:3004 $s 2>/dev/null
done

echo ""
echo "=== APLICANDO FIX Y REINICIANDO ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "Aplicando fix en $s (puerto $PORT)..."
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js
        echo "✅ Fix aplicado en $s"
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
    echo "$s:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "Aún no responde"
done
