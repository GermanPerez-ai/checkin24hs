#!/bin/bash
# Verificar qué redes son y solucionar el problema

echo "=== IDENTIFICANDO REDES ==="
echo ""

# Ver qué redes existen
echo "Redes disponibles:"
docker network ls | grep -E "easypanel|overlay"
echo ""

# Verificar qué redes tienen los servicios
echo "=== REDES DE LOS SERVICIOS ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    NET_IDS=$(docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    for net_id in $NET_IDS; do
        NET_NAME=$(docker network inspect $net_id --format '{{.Name}}' 2>/dev/null)
        echo "   Red ID $net_id = $NET_NAME"
    done
    echo ""
done

echo "=== VERIFICANDO SI EASYPANEL EXISTE ==="
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep easypanel | head -1 | awk '{print $1}')
if [ ! -z "$EASYPANEL_NET" ]; then
    echo "✅ Red easypanel encontrada: $EASYPANEL_NET"
    echo ""
    echo "=== AGREGANDO RED EASYPANEL EXPLÍCITAMENTE ==="
    for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
        echo "🔧 $s..."
        docker service update --network-add $EASYPANEL_NET $s
        sleep 2
    done
else
    echo "❌ No se encontró red easypanel"
    echo "Redes overlay disponibles:"
    docker network ls --filter "driver=overlay" --format "{{.ID}}\t{{.Name}}"
fi

echo ""
echo "=== CONFIGURANDO TRAEFIK ==="
echo ""

declare -A CONFIG=(
    ["checkin24hs_whatsapp1"]="3001:whatsapp1.checkin24hs.com"
    ["checkin24hs_whatsapp2"]="3002:whatsapp2.checkin24hs.com"
    ["checkin24hs_whatsapp3"]="3003:whatsapp3.checkin24hs.com"
    ["checkin24hs_whatsapp4"]="3004:whatsapp4.checkin24hs.com"
)

for service_name in "${!CONFIG[@]}"; do
    PORT=$(echo ${CONFIG[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${CONFIG[$service_name]} | cut -d: -f2)
    
    echo "🔧 $service_name..."
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.${service_name}.rule=Host(\`${DOMAIN}\`)" \
        --label-add "traefik.http.routers.${service_name}.entrypoints=websecure" \
        --label-add "traefik.http.routers.${service_name}.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.${service_name}.loadbalancer.server.port=${PORT}" \
        $service_name
    sleep 3
done

echo ""
echo "⏳ Esperando 20 segundos..."
sleep 20

echo ""
echo "=== VERIFICACIÓN FINAL ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    NET_IDS=$(docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    EASYPANEL_FOUND=false
    for net_id in $NET_IDS; do
        NET_NAME=$(docker network inspect $net_id --format '{{.Name}}' 2>/dev/null)
        if echo "$NET_NAME" | grep -q easypanel; then
            EASYPANEL_FOUND=true
            echo "   ✅ En red easypanel ($NET_NAME)"
        fi
    done
    if [ "$EASYPANEL_FOUND" = false ]; then
        echo "   ⚠️  No se encontró easypanel en las redes"
    fi
    
    COUNT=$(docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
    echo "   Etiquetas Traefik: $COUNT"
    if [ "$COUNT" -gt 0 ]; then
        docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.services" | head -1 | sed 's/^/      /'
    fi
    echo ""
done






