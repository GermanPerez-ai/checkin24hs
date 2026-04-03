#!/bin/bash
# Ejecutar EN EL SERVIDOR después de cada deploy en EasyPanel.
# Reaplica los labels de Traefik para que no aparezca 404 (EasyPanel a veces los pierde).
# Uso: ./scripts/reaplicar_traefik_despues_deploy.sh
# O desde la raíz del repo: bash scripts/reaplicar_traefik_despues_deploy.sh

set -e
cd "$(dirname "$0")/.."

echo "=========================================="
echo "  Reaplicar Traefik (post-deploy)"
echo "=========================================="

# Red por si no está
docker network inspect easypanel >/dev/null 2>&1 || docker network create easypanel

apply_web() {
  # EasyPanel puede crear checkin24hs_web (compose) o checkin24hs_appwebcheckin24hs (UI)
  WEB_SVC=""
  docker service ls --format "{{.Name}}" | grep -q "^checkin24hs_web$" && WEB_SVC="checkin24hs_web"
  [ -z "$WEB_SVC" ] && docker service ls --format "{{.Name}}" | grep -q "^checkin24hs_appwebcheckin24hs$" && WEB_SVC="checkin24hs_appwebcheckin24hs"
  if [ -n "$WEB_SVC" ]; then
    echo ""
    echo "  Web (www.checkin24hs.com) [$WEB_SVC]..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.docker.network=easypanel" \
      --label-add "traefik.http.routers.web.rule=Host(\`www.checkin24hs.com\`) || Host(\`checkin24hs.com\`)" \
      --label-add "traefik.http.routers.web.entrypoints=websecure" \
      --label-add "traefik.http.routers.web.service=web" \
      --label-add "traefik.http.routers.web.tls=true" \
      --label-add "traefik.http.routers.web.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.web.loadbalancer.server.port=80" \
      "$WEB_SVC" 2>/dev/null || true
    echo "  OK web"
  fi
}

apply_cotizador() {
  if docker service ls --format "{{.Name}}" | grep -q "^checkin24hs_cotizador$"; then
    echo ""
    echo "  Cotizador (cotizar.checkin24hs.com)..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.docker.network=easypanel" \
      --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
      --label-add "traefik.http.routers.cotizador.service=cotizador" \
      --label-add "traefik.http.routers.cotizador.tls=true" \
      --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.cotizador.loadbalancer.server.port=80" \
      checkin24hs_cotizador 2>/dev/null || true
    echo "  OK cotizador"
  fi
}

apply_webmail() {
  if docker service ls --format "{{.Name}}" | grep -q "^checkin24hs_webmail$"; then
    echo ""
    echo "  Webmail (webmail.checkin24hs.com)..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.docker.network=easypanel" \
      --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
      --label-add "traefik.http.routers.webmail.service=webmail" \
      --label-add "traefik.http.routers.webmail.tls=true" \
      --label-add "traefik.http.routers.webmail.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
      checkin24hs_webmail 2>/dev/null || true
    echo "  OK webmail"
  fi
}

apply_whatsapp() {
  if docker service ls --format "{{.Name}}" | grep -q "^checkin24hs_whatsapp$"; then
    echo ""
    echo "  WhatsApp (whatsapp.checkin24hs.com)..."
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
      checkin24hs_whatsapp 2>/dev/null || true
    echo "  OK whatsapp"
  fi
}

apply_web
apply_cotizador
apply_webmail
apply_whatsapp

echo ""
echo "  Esperando 10 s para que Traefik lea los labels..."
sleep 10
echo ""
echo "  Listo. Probá: https://www.checkin24hs.com  https://cotizar.checkin24hs.com  https://webmail.checkin24hs.com  https://whatsapp.checkin24hs.com"
echo ""
