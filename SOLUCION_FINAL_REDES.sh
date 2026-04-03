#!/bin/bash
echo "=== IDENTIFICANDO REDES ==="
docker network ls | grep -E "easypanel|overlay"
echo ""

# Encontrar la red easypanel por ID
EASYPANEL_ID=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep easypanel | head -1 | awk '{print $1}')
echo "Red easypanel ID: $EASYPANEL_ID"
echo ""

echo "=== CONFIGURANDO SERVICIOS ==="
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
    
    # Agregar red easypanel por ID si existe
    if [ ! -z "$EASYPANEL_ID" ]; then
        docker service update --network-add $EASYPANEL_ID $service_name 2>/dev/null
    fi
    
    # Agregar etiquetas Traefik
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
echo "⏳ Esperando 30 segundos..."
sleep 30

echo ""
echo "=== VERIFICACIÓN ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    COUNT=$(docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
    echo "   Etiquetas Traefik: $COUNT"
    if [ "$COUNT" -gt 0 ]; then
        docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.services" | head -1
    fi
done
