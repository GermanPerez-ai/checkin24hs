#!/bin/bash

# Script para agregar etiquetas de Traefik al servicio dashboard-proxy

echo "🔧 Agregando etiquetas de Traefik al servicio dashboard-proxy..."

# Obtener la configuración actual del servicio
SERVICE_NAME="checkin24hs_dashboard-proxy"

# Agregar etiquetas de Traefik usando docker service update
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard-proxy.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard-proxy.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-proxy.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard-proxy.service=dashboard-proxy" \
  --label-add "traefik.http.services.dashboard-proxy.loadbalancer.server.port=80" \
  --label-add "traefik.docker.network=easypanel" \
  $SERVICE_NAME

echo ""
echo "✅ Etiquetas de Traefik agregadas"
echo ""
echo "⏳ Espera 10-20 segundos para que Traefik detecte los cambios..."
echo ""
echo "🧪 Verifica los logs de Traefik:"
echo "   docker service logs traefik --tail 20 | grep dashboard"
