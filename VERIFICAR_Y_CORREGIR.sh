#!/bin/bash
echo "=== VERIFICACIÓN DETALLADA ==="
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    echo "   Redes configuradas:"
    docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null
    echo "   Etiquetas actuales:"
    docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -E "traefik|easypanel" | head -5
    echo ""
done

echo "=== CORRIGIENDO ==="
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
    
    echo "🔧 $service_name (puerto $PORT)..."
    
    # Agregar red easypanel si no está
    NETWORKS=$(docker service inspect $service_name --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ➕ Agregando red easypanel..."
        docker service update --network-add easypanel $service_name
        sleep 5
    fi
    
    # Agregar todas las etiquetas en un solo comando docker service update
    echo "   ➕ Agregando etiquetas Traefik (todas juntas)..."
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.${service_name}.rule=Host(\`${DOMAIN}\`)" \
        --label-add "traefik.http.routers.${service_name}.entrypoints=websecure" \
        --label-add "traefik.http.routers.${service_name}.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.${service_name}.loadbalancer.server.port=${PORT}" \
        $service_name
    
    sleep 5
    echo "   ✅ Completado"
    echo ""
done

echo "⏳ Esperando 30 segundos..."
sleep 30

echo ""
echo "=== VERIFICACIÓN FINAL ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    NET=$(docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    echo "$NET" | grep -q easypanel && echo "   ✅ En easypanel" || echo "   ❌ NO en easypanel"
    COUNT=$(docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
    echo "   Etiquetas Traefik: $COUNT"
    if [ "$COUNT" -gt 0 ]; then
        docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.services" | head -1 | sed 's/^/      /'
    fi
    echo ""
done
