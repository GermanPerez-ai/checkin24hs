#!/bin/bash
# Aplicar labels de SSL a servicios de WhatsApp en Docker Swarm

echo "=== APLICANDO LABELS SSL A SERVICIOS WHATSAPP ==="
echo ""

# Servicios encontrados:
# checkin24hs_whatsapp -> api1.checkin24hs.com
# checkin24hs_whatsapp2 -> api2.checkin24hs.com
# checkin24hs_whatsapp3 -> api3.checkin24hs.com
# checkin24hs_whatsapp4 -> api4.checkin24hs.com

declare -A SERVICES=(
    ["1"]="checkin24hs_whatsapp"
    ["2"]="checkin24hs_whatsapp2"
    ["3"]="checkin24hs_whatsapp3"
    ["4"]="checkin24hs_whatsapp4"
)

for i in 1 2 3 4; do
    SERVICE_NAME="${SERVICES[$i]}"
    SUBDOMAIN="api${i}.checkin24hs.com"
    
    echo "📋 Configurando $SERVICE_NAME para $SUBDOMAIN..."
    
    # Verificar que el servicio existe
    if ! docker service ls | grep -q "^${SERVICE_NAME} "; then
        echo "   ⚠️ Servicio no encontrado: $SERVICE_NAME"
        continue
    fi
    
    echo "   ✅ Servicio encontrado"
    
    # Obtener puerto del servicio (normalmente 3000)
    PORT=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null || echo "3000")
    if [ -z "$PORT" ] || [ "$PORT" = "0" ]; then
        PORT="3000"
    fi
    
    echo "   🔧 Puerto detectado: $PORT"
    
    # Aplicar labels SSL
    echo "   📝 Aplicando labels SSL..."
    
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.whatsapp-api${i}.rule=Host(\`${SUBDOMAIN}\`)" \
        --label-add "traefik.http.routers.whatsapp-api${i}.entrypoints=websecure" \
        --label-add "traefik.http.routers.whatsapp-api${i}.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.routers.whatsapp-api${i}.service=whatsapp-api${i}" \
        --label-add "traefik.http.services.whatsapp-api${i}.loadbalancer.server.port=${PORT}" \
        $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Labels aplicados correctamente a $SERVICE_NAME"
    else
        echo "   ⚠️ Hubo un problema aplicando los labels a $SERVICE_NAME"
    fi
    
    echo ""
done

echo "✅ Proceso completado"
echo ""
echo "📋 Verificando labels aplicados..."
echo ""
for i in 1 2 3 4; do
    SERVICE_NAME="${SERVICES[$i]}"
    echo "=== Labels de $SERVICE_NAME ==="
    docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
    echo ""
done

echo "⏳ Espera 2-5 minutos para que Let's Encrypt genere los certificados"
echo ""
echo "🔍 Verifica con:"
echo "   curl -I https://api1.checkin24hs.com"
echo "   curl -I https://api2.checkin24hs.com"
echo "   curl -I https://api3.checkin24hs.com"
echo "   curl -I https://api4.checkin24hs.com"
echo ""






