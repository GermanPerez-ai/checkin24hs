#!/bin/bash
# Solucionar error Bad Gateway en servicios de WhatsApp

echo "=== Solucionando Bad Gateway ==="
echo ""

# Configuración
declare -A SERVICES=(
    ["checkin24hs_whatsapp1"]="3001:whatsapp1.checkin24hs.com"
    ["checkin24hs_whatsapp2"]="3002:whatsapp2.checkin24hs.com"
    ["checkin24hs_whatsapp3"]="3003:whatsapp3.checkin24hs.com"
    ["checkin24hs_whatsapp4"]="3004:whatsapp4.checkin24hs.com"
)

for service_name in "${!SERVICES[@]}"; do
    PORT=$(echo ${SERVICES[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${SERVICES[$service_name]} | cut -d: -f2)
    
    echo "🔧 Configurando $service_name..."
    
    # 1. Asegurar que está en easypanel
    NETWORKS=$(docker service inspect $service_name --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ➕ Agregando a red easypanel..."
        docker service update --network-add easypanel $service_name
        sleep 2
    fi
    
    # 2. Configurar etiquetas Traefik (una por una para evitar problemas)
    echo "   ➕ Configurando Traefik..."
    
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
    
    echo "   ✅ $service_name configurado"
    echo ""
done

echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

echo ""
echo "✅ Configuración completada"
echo ""
echo "Verifica las etiquetas:"
for service_name in "${!SERVICES[@]}"; do
    echo "📋 $service_name:"
    docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | head -3
    echo ""
done






