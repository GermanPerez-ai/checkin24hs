#!/bin/bash
# Aplica labels Traefik al servicio WhatsApp (Host completo: /qr, /api/*, raíz).
# Tras redeploy en EasyPanel a veces se pierden labels → 404 en https://whatsapp.checkin24hs.com
# Ejecutar en el SERVIDOR: bash scripts/aplicar_traefik_whatsapp_servidor.sh
# Requiere: nombre correcto del servicio Swarm (por defecto checkin24hs_whatsapp).

set -e
SERVICE="${1:-checkin24hs_whatsapp}"

echo "=== Traefik → WhatsApp (${SERVICE}) — regla Host sin PathPrefix (/qr y /api) ==="
echo ""

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.whatsapp.middlewares=whatsapp-cors,whatsapp-body" \
  --label-add "traefik.http.routers.whatsapp.priority=100" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.tls=true" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.middlewares=whatsapp-cors,whatsapp-body" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.priority=100" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowmethods=GET,POST,OPTIONS" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowheaders=Content-Type,Authorization,Accept" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolalloworiginlist=https://dashboard.checkin24hs.com,https://www.checkin24hs.com" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Methods=GET, POST, OPTIONS" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Headers=Content-Type, Authorization, Accept" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Credentials=true" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolmaxage=86400" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.addvaryheader=true" \
  --label-add "traefik.http.middlewares.whatsapp-body.buffering.maxRequestBodyBytes=33554432" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE"

echo ""
echo "=== Listo. Esperá ~30s y probá: ==="
echo "  https://whatsapp.checkin24hs.com/api/health"
echo "  https://whatsapp.checkin24hs.com/api/qr"
echo "  https://whatsapp.checkin24hs.com/qr"
