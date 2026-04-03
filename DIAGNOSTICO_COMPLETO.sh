#!/bin/bash
echo "=== DIAGNÓSTICO COMPLETO ==="
echo ""

echo "1️⃣ Servicios corriendo:"
docker service ls | grep whatsapp
echo ""

echo "2️⃣ Probando conectividad desde red easypanel:"
EASYPANEL_ID=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "📋 $s (puerto $PORT):"
    docker run --rm --network $EASYPANEL_ID alpine/curl:latest curl -I --max-time 5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ❌ No responde"
done

echo ""
echo "3️⃣ Logs de Traefik (errores recientes):"
docker service logs traefik --tail 100 2>&1 | grep -iE "whatsapp|502|bad|gateway|error" | tail -20

echo ""
echo "4️⃣ Verificando red easypanel en cada servicio:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null | while read net_id; do
        NET_NAME=$(docker network inspect $net_id --format '{{.Name}}' 2>/dev/null)
        echo "   $NET_NAME"
    done
done
