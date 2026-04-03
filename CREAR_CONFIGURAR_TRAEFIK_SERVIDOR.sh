#!/bin/bash
# Crear CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh directamente en el servidor con formato Unix

cat > /root/checkin24hs/CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh << 'SCRIPTEOF'
#!/bin/bash
# Configurar Traefik para los 4 servicios de WhatsApp

echo "=== Configurar Traefik para WhatsApp 1-4 ==="
echo ""

# Configuración de los servicios
declare -A WHATSAPP_SERVICES=(
    ["whatsapp1"]="3001"
    ["whatsapp2"]="3002"
    ["whatsapp3"]="3003"
    ["whatsapp4"]="3004"
)

# Función para configurar un servicio
configurar_servicio() {
    local SERVICE_NAME=$1
    local PORT=$2
    local DOMAIN=$3
    
    echo "🔧 Configurando $SERVICE_NAME (puerto $PORT)..."
    
    # Verificar que el servicio existe
    if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
        echo "   ⚠️  Servicio $SERVICE_NAME no encontrado"
        echo "   Buscando servicios similares..."
        docker service ls --format "{{.Name}}" | grep -i whatsapp | grep -i "$PORT" || echo "   No se encontró servicio para puerto $PORT"
        return 1
    fi
    
    # Verificar que está en la red easypanel
    NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ➕ Agregando a red easypanel..."
        docker service update --network-add easypanel $SERVICE_NAME
        sleep 3
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

# Buscar servicios de WhatsApp
echo "1️⃣ Buscando servicios de WhatsApp..."
ALL_SERVICES=$(docker service ls --format "{{.Name}}")
WHATSAPP_FOUND=false

for service_name in "${!WHATSAPP_SERVICES[@]}"; do
    PORT=${WHATSAPP_SERVICES[$service_name]}
    DOMAIN="${service_name}.checkin24hs.com"
    
    # Buscar servicio por nombre o puerto
    FOUND_SERVICE=$(echo "$ALL_SERVICES" | grep -iE "whatsapp|${service_name}" | grep -i "$PORT" | head -1)
    
    if [ -z "$FOUND_SERVICE" ]; then
        # Buscar por puerto en contenedores
        CONTAINER_PORT=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "$PORT" | awk '{print $1}' | head -1)
        if [ ! -z "$CONTAINER_PORT" ]; then
            # Obtener nombre del servicio desde el contenedor
            FOUND_SERVICE=$(docker inspect $CONTAINER_PORT --format '{{index .Config.Labels "com.docker.swarm.service.name"}}' 2>/dev/null)
        fi
    fi
    
    if [ ! -z "$FOUND_SERVICE" ]; then
        WHATSAPP_FOUND=true
        echo "   ✅ Encontrado: $FOUND_SERVICE (puerto $PORT)"
        configurar_servicio "$FOUND_SERVICE" "$PORT" "$DOMAIN"
    else
        echo "   ⚠️  No se encontró servicio para $service_name (puerto $PORT)"
    fi
done

echo ""

# Si no se encontraron servicios, mostrar ayuda
if [ "$WHATSAPP_FOUND" = false ]; then
    echo "❌ No se encontraron servicios de WhatsApp"
    echo ""
    echo "📋 Servicios disponibles:"
    docker service ls
    echo ""
    echo "📋 Contenedores en puertos 3001-3004:"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004" || echo "   No hay contenedores en estos puertos"
    echo ""
    echo "💡 Crea los servicios primero en EasyPanel:"
    echo "   - whatsapp1 (puerto 3001)"
    echo "   - whatsapp2 (puerto 3002)"
    echo "   - whatsapp3 (puerto 3003)"
    echo "   - whatsapp4 (puerto 3004)"
    exit 1
fi

# Esperar a que Traefik detecte los cambios
echo "2️⃣ Esperando a que Traefik detecte los cambios..."
sleep 10

# Verificar configuración
echo "3️⃣ Verificando configuración aplicada..."
for service_name in "${!WHATSAPP_SERVICES[@]}"; do
    PORT=${WHATSAPP_SERVICES[$service_name]}
    echo ""
    echo "📋 $service_name (puerto $PORT):"
    
    # Buscar el servicio real
    FOUND_SERVICE=$(docker service ls --format "{{.Name}}" | grep -iE "whatsapp|${service_name}" | grep -i "$PORT" | head -1)
    
    if [ ! -z "$FOUND_SERVICE" ]; then
        docker service inspect $FOUND_SERVICE --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | head -5
    fi
done

echo ""
echo "4️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 30 2>&1 | grep -iE "whatsapp|3001|3002|3003|3004" | tail -10 || echo "   No hay referencias aún en los logs"
echo ""

echo "=== CONFIGURACIÓN COMPLETADA ==="
echo ""
echo "✅ Traefik configurado para los servicios de WhatsApp"
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
SCRIPTEOF

chmod +x /root/checkin24hs/CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh

echo "✅ Archivo creado con formato Unix correcto"
echo ""
echo "Ahora puedes ejecutar:"
echo "  bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"


















