#!/bin/bash
# Verificar y corregir completamente la configuración

echo "=== VERIFICACIÓN DETALLADA ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    echo "   Redes:"
    docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null
    echo "   Todas las etiquetas:"
    docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | head -10
    echo ""
done

echo "=== CORRIGIENDO CONFIGURACIÓN ==="
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
    
    # Verificar si ya tiene la red easypanel
    NETWORKS=$(docker service inspect $service_name --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ➕ Agregando red easypanel..."
        docker service update --network-add easypanel $service_name
        sleep 5
    else
        echo "   ✅ Ya está en easypanel"
    fi
    
    # Agregar todas las etiquetas en un solo comando
    echo "   ➕ Agregando etiquetas Traefik..."
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.${service_name}.rule=Host(\`${DOMAIN}\`)" \
        --label-add "traefik.http.routers.${service_name}.entrypoints=websecure" \
        --label-add "traefik.http.routers.${service_name}.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.${service_name}.loadbalancer.server.port=${PORT}" \
        $service_name
    
    sleep 3
    echo "   ✅ Configurado"
    echo ""
done

echo "⏳ Esperando 20 segundos..."
sleep 20

echo ""
echo "=== VERIFICACIÓN FINAL ==="
echo ""

for service_name in "${!CONFIG[@]}"; do
    PORT=$(echo ${CONFIG[$service_name]} | cut -d: -f1)
    
    echo "📋 $service_name:"
    
    # Verificar redes
    NETWORKS=$(docker service inspect $service_name --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ✅ En easypanel"
    else
        echo "   ❌ NO en easypanel"
        echo "   Redes actuales: $NETWORKS"
    fi
    
    # Verificar etiquetas Traefik
    TRAEFIK_COUNT=$(docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
    echo "   Etiquetas Traefik: $TRAEFIK_COUNT"
    if [ "$TRAEFIK_COUNT" -gt 0 ]; then
        docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | head -5 | sed 's/^/      /'
    fi
    
    echo ""
done






