#!/bin/bash

# Script para agregar etiquetas de Traefik al servicio dashboard

echo "🔧 Agregando etiquetas de Traefik al servicio dashboard..."

# Agregar etiquetas de Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --label-add "traefik.docker.network=easypanel" \
  checkin24hs_dashboard

echo ""
echo "✅ Etiquetas agregadas"
echo ""
echo "⏳ Espera 20-30 segundos para que Traefik detecte los cambios..."
echo ""
echo "🧪 Verifica:"
echo "   docker service logs traefik --tail 20 | grep dashboard"
