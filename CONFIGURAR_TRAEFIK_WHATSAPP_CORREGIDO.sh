#!/bin/bash
# Configurar Traefik para los 4 servicios de WhatsApp (versión corregida)

echo "=== Configurar Traefik para WhatsApp 1-4 ==="
echo ""

# Configuración de los servicios (nombre exacto del servicio Docker)
declare -A WHATSAPP_SERVICES=(
    ["checkin24hs_whatsapp1"]="3001:whatsapp1.checkin24hs.com"
    ["checkin24hs_whatsapp2"]="3002:whatsapp2.checkin24hs.com"
    ["checkin24hs_whatsapp3"]="3003:whatsapp3.checkin24hs.com"
    ["checkin24hs_whatsapp4"]="3004:whatsapp4.checkin24hs.com"
)

# Función para configurar un servicio
configurar_servicio() {
    local SERVICE_NAME=$1
    local PORT=$2
    local DOMAIN=$3
    
    echo "🔧 Configurando $SERVICE_NAME (puerto $PORT)..."
    
    # Verificar que el servicio existe
    if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
        echo "   ❌ Servicio $SERVICE_NAME no encontrado"
        return 1
    fi
    
    # Verificar que está en la red easypanel
    NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ➕ Agregando a red easypanel..."
        docker service update --network-add easypanel $SERVICE_NAME
        sleep 3
    else
        echo "   ✅ Ya está en red easypanel"
    fi
    
    # Configurar etiquetas Traefik
    echo "   ➕ Agregando etiquetas Traefik..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.${SERVICE_NAME}.rule=Host(\`${DOMAIN}\`)" \
      --label-add "traefik.http.routers.${SERVICE_NAME}.entrypoints=websecure" \
      --label-add "traefik.http.routers.${SERVICE_NAME}.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server.port=${PORT}" \
      $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        echo "   ✅ $SERVICE_NAME configurado correctamente"
    else
        echo "   ❌ Error al configurar $SERVICE_NAME"
        return 1
    fi
    
    echo ""
}

# Configurar cada servicio
echo "1️⃣ Configurando servicios de WhatsApp..."
echo ""

CONFIGURADOS=0
for service_name in "${!WHATSAPP_SERVICES[@]}"; do
    CONFIG=$(echo ${WHATSAPP_SERVICES[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${WHATSAPP_SERVICES[$service_name]} | cut -d: -f2)
    
    if docker service ls --format "{{.Name}}" | grep -q "^${service_name}$"; then
        echo "   ✅ Encontrado: $service_name"
        configurar_servicio "$service_name" "$CONFIG" "$DOMAIN"
        CONFIGURADOS=$((CONFIGURADOS + 1))
    else
        echo "   ⚠️  No encontrado: $service_name"
    fi
done

echo ""

if [ $CONFIGURADOS -eq 0 ]; then
    echo "❌ No se encontraron servicios de WhatsApp"
    echo ""
    echo "Servicios disponibles:"
    docker service ls | grep -i whatsapp || echo "   No hay servicios de WhatsApp"
    exit 1
fi

# Esperar a que Traefik detecte los cambios
echo "2️⃣ Esperando a que Traefik detecte los cambios..."
sleep 15

# Verificar configuración
echo "3️⃣ Verificando configuración aplicada..."
echo ""

for service_name in "${!WHATSAPP_SERVICES[@]}"; do
    PORT=$(echo ${WHATSAPP_SERVICES[$service_name]} | cut -d: -f1)
    DOMAIN=$(echo ${WHATSAPP_SERVICES[$service_name]} | cut -d: -f2)
    
    if docker service ls --format "{{.Name}}" | grep -q "^${service_name}$"; then
        echo "📋 $service_name (puerto $PORT, dominio $DOMAIN):"
        TRAEFIK_LABELS=$(docker service inspect $service_name --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
        if [ ! -z "$TRAEFIK_LABELS" ]; then
            echo "$TRAEFIK_LABELS" | head -5 | sed 's/^/   /'
        else
            echo "   ⚠️  No se encontraron etiquetas Traefik"
        fi
        echo ""
    fi
done

echo "4️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 50 2>&1 | grep -iE "whatsapp|3001|3002|3003|3004" | tail -15 || echo "   No hay referencias aún en los logs"
echo ""

echo "=== CONFIGURACIÓN COMPLETADA ==="
echo ""
echo "✅ Traefik configurado para $CONFIGURADOS servicios de WhatsApp"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Configurar DNS para los 4 dominios:"
echo "      - whatsapp1.checkin24hs.com → 72.61.58.240"
echo "      - whatsapp2.checkin24hs.com → 72.61.58.240"
echo "      - whatsapp3.checkin24hs.com → 72.61.58.240"
echo "      - whatsapp4.checkin24hs.com → 72.61.58.240"
echo "   2. Esperar propagación DNS (puede tardar hasta 24 horas)"
echo "   3. Esperar generación de certificados SSL (puede tardar unos minutos)"
echo "   4. Probar:"
echo "      curl -I https://whatsapp1.checkin24hs.com"
echo "      curl -I https://whatsapp2.checkin24hs.com"
echo "      curl -I https://whatsapp3.checkin24hs.com"
echo "      curl -I https://whatsapp4.checkin24hs.com"
echo ""
