#!/bin/bash

# Script para restaurar etiquetas de Traefik después de implementar

echo "🔧 Restaurando etiquetas de Traefik para dashboard..."

# Verificar si hay etiquetas
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

# Verificar si hay etiquetas
if [ -z "$(docker inspect $DASHBOARD_ID | grep -A 40 "Labels" | grep -i traefik)" ]; then
    echo "📝 Agregando etiquetas de Traefik..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
      --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.routers.dashboard.service=dashboard" \
      --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
      --label-add "traefik.docker.network=easypanel" \
      checkin24hs_dashboard
    echo "✅ Etiquetas agregadas"
    echo "⏳ Espera 20-30 segundos para que Traefik detecte los cambios"
else
    echo "✅ Las etiquetas de Traefik ya están presentes"
fi
