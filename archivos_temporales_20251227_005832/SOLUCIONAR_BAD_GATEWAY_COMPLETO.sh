#!/bin/bash
# Solución completa para Bad Gateway

echo "=== SOLUCIONANDO BAD GATEWAY ==="
echo ""

# Configuración
declare -A CONFIG=(
    ["checkin24hs_whatsapp1"]="3001:whatsapp1.checkin24hs.com"
    ["checkin24hs_whatsapp2"]="3002:whatsapp2.checkin24hs.com"
    ["checkin24hs_whatsapp3"]="3003:whatsapp3.checkin24hs.com"
    ["checkin24hs_whatsapp4"]="3004:whatsapp4.checkin24hs.com"
)

for service_name in "${!CONFIG[@]}"; do
    PORT=$(echo ${CONFIG[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${CONFIG[$service_name]} | cut -d: -f2)
    
    echo "🔧 Configurando $service_name (puerto $PORT, dominio $DOMAIN)..."
    
    # 1. Asegurar red easypanel
    echo "   ➕ Red easypanel..."
    docker service update --network-add easypanel $service_name 2>/dev/null
    sleep 2
    
    # 2. Eliminar etiquetas Traefik antiguas (si existen)
    echo "   🗑️  Limpiando etiquetas antiguas..."
    docker service update --label-rm "traefik.enable" $service_name 2>/dev/null
    docker service update --label-rm "traefik.http.routers.${service_name}.rule" $service_name 2>/dev/null
    docker service update --label-rm "traefik.http.routers.${service_name}.entrypoints" $service_name 2>/dev/null
    docker service update --label-rm "traefik.http.routers.${service_name}.tls.certresolver" $service_name 2>/dev/null
    docker service update --label-rm "traefik.http.services.${service_name}.loadbalancer.server.port" $service_name 2>/dev/null
    sleep 2
    
    # 3. Agregar etiquetas Traefik correctas (una por una)
    echo "   ➕ Agregando etiquetas Traefik..."
    
    docker service update --label-add "traefik.enable=true" $service_name
    sleep 1
    
    docker service update --label-add "traefik.http.routers.${service_name}.rule=Host(\`${DOMAIN}\`)" $service_name
    sleep 1
    
    docker service update --label-add "traefik.http.routers.${service_name}.entrypoints=websecure" $service_name
    sleep 1
    
    docker service update --label-add "traefik.http.routers.${service_name}.tls.certresolver=letsencrypt" $service_name
    sleep 1
    
    # IMPORTANTE: Usar el puerto TARGET, no el publicado
    docker service update --label-add "traefik.http.services.${service_name}.loadbalancer.server.port=${PORT}" $service_name
    sleep 2
    
    echo "   ✅ $service_name configurado"
    echo ""
done

echo "⏳ Esperando 20 segundos para que Traefik detecte los cambios..."
sleep 20

echo ""
echo "✅ Verificando configuración final:"
for service_name in "${!CONFIG[@]}"; do
    PORT=$(echo ${CONFIG[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${CONFIG[$service_name]} | cut -d: -f2)
    
    echo "📋 $service_name:"
    TRAEFIK=$(docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
    if [ ! -z "$TRAEFIK" ]; then
        echo "$TRAEFIK" | head -6 | sed 's/^/   /'
    else
        echo "   ⚠️  No se encontraron etiquetas Traefik"
    fi
    echo ""
done

echo "=== SOLUCIÓN APLICADA ==="
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  - https://whatsapp1.checkin24hs.com"
echo "  - https://whatsapp2.checkin24hs.com"
echo "  - https://whatsapp3.checkin24hs.com"
echo "  - https://whatsapp4.checkin24hs.com"
echo ""






