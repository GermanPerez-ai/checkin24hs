#!/bin/bash
echo "=== Solucionando Bad Gateway ==="
echo ""

declare -A SERVICES=(
    ["checkin24hs_whatsapp1"]="3001:whatsapp1.checkin24hs.com"
    ["checkin24hs_whatsapp2"]="3002:whatsapp2.checkin24hs.com"
    ["checkin24hs_whatsapp3"]="3003:whatsapp3.checkin24hs.com"
    ["checkin24hs_whatsapp4"]="3004:whatsapp4.checkin24hs.com"
)

for service_name in "${!SERVICES[@]}"; do
    PORT=$(echo ${SERVICES[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${SERVICES[$service_name]} | cut -d: -f2)
    
    echo "🔧 $service_name (puerto $PORT)..."
    
    # Asegurar red easypanel
    docker service update --network-add easypanel $service_name 2>/dev/null
    sleep 1
    
    # Configurar Traefik (una etiqueta a la vez)
    docker service update --label-add "traefik.enable=true" $service_name
    sleep 1
    docker service update --label-add "traefik.http.routers.${service_name}.rule=Host(\`${DOMAIN}\`)" $service_name
    sleep 1
    docker service update --label-add "traefik.http.routers.${service_name}.entrypoints=websecure" $service_name
    sleep 1
    docker service update --label-add "traefik.http.routers.${service_name}.tls.certresolver=letsencrypt" $service_name
    sleep 1
    docker service update --label-add "traefik.http.services.${service_name}.loadbalancer.server.port=${PORT}" $service_name
    sleep 2
    
    echo "   ✅ Configurado"
done

echo ""
echo "⏳ Esperando 20 segundos..."
sleep 20

echo ""
echo "✅ Verificando configuración:"
for service_name in "${!SERVICES[@]}"; do
    echo "📋 $service_name:"
    docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.services" | head -1
done
