#!/bin/bash
# Script completo para configurar SSL con Let's Encrypt para servicios de WhatsApp

echo "=== CONFIGURACIÓN COMPLETA DE SSL PARA WHATSAPP ==="
echo ""

# Verificar servicios de WhatsApp
echo "📋 Buscando servicios de WhatsApp..."
SERVICES=$(docker service ls --format "{{.Name}}" | grep -i whatsapp)

if [ -z "$SERVICES" ]; then
    echo "⚠️ No se encontraron servicios de WhatsApp"
    echo ""
    echo "Todos los servicios disponibles:"
    docker service ls
    exit 1
fi

echo "✅ Servicios encontrados:"
echo "$SERVICES"
echo ""

# Mapear servicios a subdominios (ajustar según nombres reales)
declare -A SERVICE_MAP
for service in $SERVICES; do
    if echo "$service" | grep -qE "whatsapp$|whatsapp[^0-9]"; then
        SERVICE_MAP["$service"]="api1.checkin24hs.com"
    elif echo "$service" | grep -q "whatsapp2"; then
        SERVICE_MAP["$service"]="api2.checkin24hs.com"
    elif echo "$service" | grep -q "whatsapp3"; then
        SERVICE_MAP["$service"]="api3.checkin24hs.com"
    elif echo "$service" | grep -q "whatsapp4"; then
        SERVICE_MAP["$service"]="api4.checkin24hs.com"
    fi
done

echo "=== APLICANDO CONFIGURACIÓN SSL ==="
echo ""

for service in $SERVICES; do
    SUBDOMAIN="${SERVICE_MAP[$service]}"
    
    if [ -z "$SUBDOMAIN" ]; then
        echo "⚠️ No se pudo determinar subdominio para $service"
        echo "   Labels actuales:"
        docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -5 || echo "   (sin labels traefik)"
        echo ""
        continue
    fi
    
    echo "📋 Configurando $service para $SUBDOMAIN..."
    
    # Obtener puerto
    PORT=$(docker service inspect $service --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null | head -n 1)
    if [ -z "$PORT" ] || [ "$PORT" = "0" ]; then
        PORT="3000"
    fi
    
    echo "   Puerto: $PORT"
    
    # Aplicar labels SSL
    echo "   Aplicando labels SSL con Let's Encrypt..."
    
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.${service}.rule=Host(\`${SUBDOMAIN}\`)" \
        --label-add "traefik.http.routers.${service}.entrypoints=websecure" \
        --label-add "traefik.http.routers.${service}.tls=true" \
        --label-add "traefik.http.routers.${service}.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.${service}.loadbalancer.server.port=${PORT}" \
        $service 2>&1 | grep -v "since no changes were detected" || true
    
    echo "   ✅ Labels aplicados"
    echo ""
done

echo "✅ Configuración completada"
echo ""
echo "⏳ Espera 2-5 minutos para que Let's Encrypt genere los certificados"
echo ""
echo "🔍 Verifica los certificados con:"
echo "   openssl s_client -servername api1.checkin24hs.com -connect api1.checkin24hs.com:443 </dev/null 2>/dev/null | openssl x509 -noout -subject"
echo ""
echo "Deberías ver el dominio real (api1.checkin24hs.com) en lugar de 'TRAEFIK DEFAULT CERT'"
echo ""






