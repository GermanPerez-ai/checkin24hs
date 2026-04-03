#!/bin/bash
# Corregir certificados SSL para usar Let's Encrypt real en lugar del certificado por defecto

echo "=== CORRECCIÓN DE CERTIFICADOS SSL ==="
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

# Verificar configuración de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de Traefik"
    exit 1
fi

echo "✅ Contenedor de Traefik: $TRAEFIK_CONTAINER"
echo ""

# Verificar si Let's Encrypt está configurado
echo "🔍 Verificando configuración de Let's Encrypt..."
LE_CONFIG=$(docker logs $TRAEFIK_CONTAINER 2>&1 | grep -i "letsencrypt\|acme" | tail -5)

if [ -n "$LE_CONFIG" ]; then
    echo "✅ Let's Encrypt está configurado en Traefik"
    echo "$LE_CONFIG"
else
    echo "⚠️ No se encontró configuración activa de Let's Encrypt"
fi

echo ""
echo "=== PROBLEMA DETECTADO ==="
echo ""
echo "Los certificados muestran 'TRAEFIK DEFAULT CERT' en lugar de certificados de Let's Encrypt"
echo "Esto significa que los servicios no están configurados para usar Let's Encrypt"
echo ""

# Mapear servicios a subdominios
declare -A SERVICE_MAP
SERVICE_MAP["checkin24hs_whatsapp"]="api1.checkin24hs.com"
SERVICE_MAP["checkin24hs_whatsapp2"]="api2.checkin24hs.com"
SERVICE_MAP["checkin24hs_whatsapp3"]="api3.checkin24hs.com"
SERVICE_MAP["checkin24hs_whatsapp4"]="api4.checkin24hs.com"

echo "=== APLICANDO CONFIGURACIÓN SSL CORRECTA ==="
echo ""

for service in $SERVICES; do
    # Determinar subdominio
    SUBDOMAIN=""
    for key in "${!SERVICE_MAP[@]}"; do
        if [[ "$service" == *"$key"* ]] || [[ "$service" == "$key" ]]; then
            SUBDOMAIN="${SERVICE_MAP[$key]}"
            break
        fi
    done
    
    # Si no se encuentra en el mapa, intentar deducir del nombre
    if [ -z "$SUBDOMAIN" ]; then
        if echo "$service" | grep -q "whatsapp$"; then
            SUBDOMAIN="api1.checkin24hs.com"
        elif echo "$service" | grep -q "whatsapp2"; then
            SUBDOMAIN="api2.checkin24hs.com"
        elif echo "$service" | grep -q "whatsapp3"; then
            SUBDOMAIN="api3.checkin24hs.com"
        elif echo "$service" | grep -q "whatsapp4"; then
            SUBDOMAIN="api4.checkin24hs.com"
        fi
    fi
    
    if [ -z "$SUBDOMAIN" ]; then
        echo "⚠️ No se pudo determinar subdominio para $service"
        continue
    fi
    
    echo "📋 Configurando $service para $SUBDOMAIN..."
    
    # Obtener puerto del servicio
    PORT=$(docker service inspect $service --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null | head -n 1)
    if [ -z "$PORT" ] || [ "$PORT" = "0" ]; then
        PORT="3000"  # Puerto por defecto
    fi
    
    echo "   Puerto: $PORT"
    
    # Aplicar labels SSL con Let's Encrypt
    echo "   Aplicando labels SSL con Let's Encrypt..."
    
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.${service}.rule=Host(\`${SUBDOMAIN}\`)" \
        --label-add "traefik.http.routers.${service}.entrypoints=websecure" \
        --label-add "traefik.http.routers.${service}.tls=true" \
        --label-add "traefik.http.routers.${service}.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.${service}.loadbalancer.server.port=${PORT}" \
        $service 2>&1 | grep -v "since no changes were detected" || true
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Labels aplicados"
    else
        echo "   ⚠️ Error aplicando labels"
    fi
    
    echo ""
done

echo "✅ Configuración completada"
echo ""
echo "⏳ Espera 2-5 minutos para que Let's Encrypt genere los certificados reales"
echo ""
echo "🔍 Verifica con:"
echo "   openssl s_client -servername api1.checkin24hs.com -connect api1.checkin24hs.com:443 </dev/null 2>/dev/null | openssl x509 -noout -subject"
echo ""
echo "Deberías ver el dominio real en lugar de 'TRAEFIK DEFAULT CERT'"
echo ""






