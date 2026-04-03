#!/bin/bash
# Script rápido para reaplicar Traefik después de deploy
# Ejecutar después de cada deploy en EasyPanel

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"
ROUTER_NAME="whatsapp-main"

echo "🔄 Reaplicando Traefik labels..."

docker service update \
  --network-add easypanel \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.tls=true" \
  --label-add "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}" \
  $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true

echo "✅ Listo. Espera 10-30 segundos y prueba: https://${DOMAIN}/qr"
