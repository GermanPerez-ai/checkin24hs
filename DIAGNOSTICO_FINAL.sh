#!/bin/bash
echo "=== DIAGNÓSTICO FINAL ==="
echo ""

echo "1️⃣ Verificando puertos de los servicios:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s:"
    echo "   Puerto esperado: $PORT"
    TARGET=$(docker service inspect $s --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null)
    PUBLISHED=$(docker service inspect $s --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
    echo "   Puerto objetivo: $TARGET"
    echo "   Puerto publicado: $PUBLISHED"
    
    # Probar conectividad
    echo "   Probando conexión..."
    docker run --rm --network easypanel alpine/curl:latest curl -I --max-time 5 http://tasks.$s:$PORT 2>&1 | head -2 || echo "   ❌ No responde"
    echo ""
done

echo "2️⃣ Verificando si los contenedores están escuchando:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        echo "📋 $s (contenedor $CONTAINER):"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep ":$PORT " || docker exec $CONTAINER ss -tuln 2>/dev/null | grep ":$PORT " || echo "   ⚠️  No escucha en puerto $PORT"
    fi
done

echo ""
echo "3️⃣ Logs recientes de whatsapp4:"
docker service logs checkin24hs_whatsapp4 --tail 10 2>&1 | tail -5
