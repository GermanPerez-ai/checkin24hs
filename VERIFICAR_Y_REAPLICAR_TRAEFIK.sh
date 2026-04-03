#!/bin/bash
# Verificar y reaplicar etiquetas Traefik solo si faltan
# Este script es inteligente: solo aplica cambios si es necesario

echo "=========================================="
echo "🔍 VERIFICAR Y REAPLICAR TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"
ROUTER_NAME="whatsapp-main"

# Verificar si el servicio existe
if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "❌ Servicio $SERVICE_NAME no encontrado"
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}" | grep -i whatsapp || echo "   (ninguno encontrado)"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Obtener todas las etiquetas actuales
echo "📋 Verificando etiquetas Traefik existentes..."
CURRENT_LABELS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>/dev/null)

# Verificar cada etiqueta necesaria
NEEDS_UPDATE=false
MISSING_LABELS=()

# Etiquetas requeridas
REQUIRED_LABELS=(
    "traefik.enable=true"
    "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)"
    "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure"
    "traefik.http.routers.${ROUTER_NAME}.tls=true"
    "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt"
    "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}"
)

echo "🔍 Verificando etiquetas requeridas..."
for label in "${REQUIRED_LABELS[@]}"; do
    label_key=$(echo "$label" | cut -d'=' -f1)
    label_value=$(echo "$label" | cut -d'=' -f2-)
    
    if echo "$CURRENT_LABELS" | grep -q "^${label_key}="; then
        current_value=$(echo "$CURRENT_LABELS" | grep "^${label_key}=" | cut -d'=' -f2-)
        if [ "$current_value" != "$label_value" ]; then
            echo "   ⚠️  Etiqueta incorrecta: $label_key"
            echo "      Actual: $current_value"
            echo "      Esperado: $label_value"
            NEEDS_UPDATE=true
            MISSING_LABELS+=("$label")
        else
            echo "   ✅ $label_key"
        fi
    else
        echo "   ❌ Falta: $label_key"
        NEEDS_UPDATE=true
        MISSING_LABELS+=("$label")
    fi
done

echo ""

# Verificar red easypanel
echo "🌐 Verificando red easypanel..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if ! echo "$NETWORKS" | grep -q "easypanel"; then
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 3
    echo "   ✅ Agregado a red easypanel"
    NEEDS_UPDATE=true
else
    echo "   ✅ Ya está en red easypanel"
fi
echo ""

# Si no necesita actualización, salir
if [ "$NEEDS_UPDATE" = false ]; then
    echo "=========================================="
    echo "✅ TODAS LAS ETIQUETAS ESTÁN CORRECTAS"
    echo "=========================================="
    echo ""
    echo "No se requiere ninguna acción."
    echo ""
    exit 0
fi

# Si necesita actualización, aplicar las etiquetas
echo "=========================================="
echo "🔧 APLICANDO ETIQUETAS FALTANTES"
echo "=========================================="
echo ""

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.tls=true" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}" \
  $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true

echo ""
echo "✅ Etiquetas aplicadas"
echo ""

# Verificar nuevamente
echo "🔍 Verificando etiquetas después de la actualización..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep traefik
echo ""

# Esperar un momento para que Traefik detecte los cambios
echo "⏳ Esperando 10 segundos para que Traefik detecte los cambios..."
sleep 10

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "🌐 Prueba acceder a:"
echo "   https://${DOMAIN}/qr"
echo "   https://${DOMAIN}/api/qr"
echo "   https://${DOMAIN}/status"
echo ""
