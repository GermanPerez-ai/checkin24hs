#!/bin/bash
# Aplicar SSL sin conflictos de puertos

echo "=== APLICANDO SSL A SERVICIOS WHATSAPP ==="
echo ""

# Verificar estado actual
echo "📋 Estado actual de los servicios:"
docker service ls | grep whatsapp
echo ""

# Aplicar labels uno por uno, esperando entre cada uno
SERVICES=(
    "checkin24hs_whatsapp:api1.checkin24hs.com"
    "checkin24hs_whatsapp2:api2.checkin24hs.com"
    "checkin24hs_whatsapp3:api3.checkin24hs.com"
    "checkin24hs_whatsapp4:api4.checkin24hs.com"
)

for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r service subdomain <<< "$service_config"
    
    echo "📋 Configurando $service para $subdomain..."
    
    # Aplicar labels sin esperar a que se complete la actualización
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.${service}.rule=Host(\`${subdomain}\`)" \
        --label-add "traefik.http.routers.${service}.entrypoints=websecure" \
        --label-add "traefik.http.routers.${service}.tls=true" \
        --label-add "traefik.http.routers.${service}.tls.certresolver=letsencrypt" \
        --update-parallelism 1 \
        --update-delay 10s \
        $service 2>&1 | head -5
    
    echo "   ✅ Labels aplicados (la actualización puede continuar en segundo plano)"
    echo ""
    
    # Esperar un poco entre servicios
    sleep 5
done

echo "✅ Labels SSL aplicados a todos los servicios"
echo ""
echo "⏳ Las actualizaciones pueden continuar en segundo plano"
echo "   Verifica el progreso con: docker service ps checkin24hs_whatsapp"
echo ""
echo "🔍 Verifica los labels aplicados:"
for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r service subdomain <<< "$service_config"
    echo ""
    echo "=== $service ==="
    docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
done

echo ""
echo "⏳ Espera 2-5 minutos para que Let's Encrypt genere los certificados"
echo "   Luego verifica con:"
echo "   openssl s_client -servername api1.checkin24hs.com -connect api1.checkin24hs.com:443 </dev/null 2>/dev/null | openssl x509 -noout -subject"
echo ""






