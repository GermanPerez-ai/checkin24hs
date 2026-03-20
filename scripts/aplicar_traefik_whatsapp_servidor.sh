#!/bin/bash
# Aplica TODOS los labels de Traefik al servicio WhatsApp (routing + CORS).
# Usar cuando el QR no arranca o curl a /api/send da 404 (p. ej. tras redeploy en EasyPanel).
# Ejecutar en el SERVIDOR: bash scripts/aplicar_traefik_whatsapp_servidor.sh
# Requiere: git pull o copiar este script al servidor.

set -e
SERVICE="${1:-checkin24hs_whatsapp}"

echo "=== Aplicando labels Traefik al servicio WhatsApp (${SERVICE}) ==="
echo "Esto crea los routers para whatsapp.checkin24hs.com y CORS."
echo ""

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`) && PathPrefix(\`/api\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.whatsapp.middlewares=whatsapp-cors,whatsapp-body" \
  --label-add "traefik.http.routers.whatsapp.priority=10" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`) && PathPrefix(\`/api\`)" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.tls=true" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.middlewares=whatsapp-cors,whatsapp-body" \
  --label-add "traefik.http.routers.checkin24hs_whatsapp.priority=10" \
  --label-add "traefik.http.routers.whatsapp-root.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp-root.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp-root.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp-root.tls=true" \
  --label-add "traefik.http.routers.whatsapp-root.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.whatsapp-root.middlewares=whatsapp-cors,whatsapp-body" \
  --label-add "traefik.http.routers.whatsapp-root.priority=1" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowmethods=GET,POST,OPTIONS" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowheaders=Content-Type,Authorization,Accept" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolalloworiginlist=https://dashboard.checkin24hs.com,https://www.checkin24hs.com" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Origin=https://dashboard.checkin24hs.com" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Methods=GET, POST, OPTIONS" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Headers=Content-Type, Authorization, Accept" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Credentials=true" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolmaxage=86400" \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.addvaryheader=true" \
  --label-add "traefik.http.middlewares.whatsapp-body.buffering.maxRequestBodyBytes=33554432" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE"

echo ""
echo "=== Listo. Esperá unos 10 segundos y probá: ==="
echo "  QR:  https://whatsapp.checkin24hs.com/qr"
echo "  API: curl -i \"https://whatsapp.checkin24hs.com/api/send\""
echo "  (no debe dar 404). Luego en el dashboard: Abrir QR / Conectar WhatsApp."
