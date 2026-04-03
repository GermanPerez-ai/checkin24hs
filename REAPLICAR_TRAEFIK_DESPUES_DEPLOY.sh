#!/bin/bash
# Reaplicar etiquetas Traefik después de deploy en EasyPanel
# Este script verifica y reaplica las etiquetas si EasyPanel las eliminó

echo "=========================================="
echo "🔄 REAPLICAR TRAEFIK DESPUÉS DE DEPLOY"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"

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

# Verificar etiquetas actuales
echo "📋 Verificando etiquetas actuales..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep traefik || echo "   ⚠️  No se encontraron etiquetas Traefik"
echo ""

# Verificar red easypanel
echo "🌐 Verificando red easypanel..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if ! echo "$NETWORKS" | grep -q "easypanel"; then
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 3
    echo "   ✅ Agregado a red easypanel"
else
    echo "   ✅ Ya está en red easypanel"
fi
echo ""

# Aplicar etiquetas Traefik (usando nombre único para evitar conflictos)
echo "🔧 Aplicando etiquetas Traefik..."
echo "=========================================="

# Usar un nombre de router único para evitar conflictos con EasyPanel
ROUTER_NAME="whatsapp-main"

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

# Verificar que se aplicaron correctamente
echo "🔍 Verificando etiquetas aplicadas..."
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
echo "💡 Si aún ves 404, espera 1-2 minutos más para que Traefik"
echo "   actualice su configuración interna."
echo ""
