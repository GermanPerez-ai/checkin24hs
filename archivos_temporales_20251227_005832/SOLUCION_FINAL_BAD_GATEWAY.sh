#!/bin/bash
# Solución final para Bad Gateway - Corrige todos los problemas

echo "=== SOLUCIÓN FINAL BAD GATEWAY ==="
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
    
    echo "🔧 Configurando $service_name (puerto $PORT)..."
    
    # 1. CRÍTICO: Agregar a red easypanel
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel $service_name
    if [ $? -eq 0 ]; then
        echo "   ✅ Agregado a easypanel"
    else
        echo "   ⚠️  Error al agregar a easypanel (puede que ya esté)"
    fi
    sleep 3
    
    # 2. Configurar etiquetas Traefik
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

echo "⏳ Esperando 30 segundos para que los cambios se apliquen..."
sleep 30

echo ""
echo "✅ Verificando configuración final:"
echo ""

for service_name in "${!CONFIG[@]}"; do
    PORT=$(echo ${CONFIG[$service_name]} | cut -d: -f1)
    
    echo "📋 $service_name:"
    
    # Verificar red
    NET=$(docker service inspect $service_name --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if echo "$NET" | grep -q easypanel; then
        echo "   ✅ En red easypanel"
    else
        echo "   ❌ NO en red easypanel"
    fi
    
    # Verificar etiquetas
    TRAEFIK=$(docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
    if [ "$TRAEFIK" -gt 0 ]; then
        echo "   ✅ Etiquetas Traefik: $TRAEFIK configuradas"
        docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.services" | head -1 | sed 's/^/      /'
    else
        echo "   ❌ No hay etiquetas Traefik"
    fi
    
    # Probar conectividad
    echo "   🔍 Probando conectividad..."
    docker run --rm --network easypanel alpine/curl:latest curl -I --max-time 5 http://tasks.$service_name:$PORT 2>&1 | head -2 | grep -q "HTTP" && echo "      ✅ Conectividad OK" || echo "      ⚠️  Conectividad pendiente (puede tardar unos segundos)"
    
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
echo "Si aún ves Bad Gateway, espera 2-3 minutos más para que Traefik detecte los cambios."






