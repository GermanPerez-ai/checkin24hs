#!/bin/bash
# Reaplica Traefik para Líneas 1–4 (404 en /api/qr, /api/status).
# Uso: cd /root/checkin24hs && bash scripts/aplicar_traefik_whatsapp_ambos.sh

set -euo pipefail
cd "$(dirname "$0")/.."

apply_traefik_line() {
  local line="$1"
  local port=$((3000 + line))
  local host="whatsapp${line}.checkin24hs.com"
  local service="checkin24hs_whatsapp${line}"
  local router="whatsapp${line}"

  if [[ "$line" == "1" ]]; then
    host="whatsapp.checkin24hs.com"
    service="checkin24hs_whatsapp"
    router="whatsapp"
  fi

  echo "=== Línea $line ($host → puerto $port) ==="
  docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.docker.network=easypanel" \
    --label-add "traefik.http.routers.${router}.rule=Host(\`${host}\`)" \
    --label-add "traefik.http.routers.${router}.entrypoints=websecure" \
    --label-add "traefik.http.routers.${router}.service=${router}" \
    --label-add "traefik.http.routers.${router}.tls=true" \
    --label-add "traefik.http.routers.${router}.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.${router}.middlewares=whatsapp-cors,whatsapp-body" \
    --label-add "traefik.http.routers.${router}.priority=100" \
    --label-add "traefik.http.services.${router}.loadbalancer.server.port=${port}" \
    "$service"
}

echo "=== Línea 1 (whatsapp.checkin24hs.com → puerto 3001) ==="
bash scripts/aplicar_traefik_whatsapp_servidor.sh checkin24hs_whatsapp

for line in 2 3 4; do
  echo ""
  apply_traefik_line "$line"
done

echo ""
echo "=== Verificar (esperá ~20s) ==="
sleep 20
for line in 1 2 3 4; do
  host="whatsapp${line}.checkin24hs.com"
  [[ "$line" == "1" ]] && host="whatsapp.checkin24hs.com"
  curl -sf "https://${host}/api/health" && echo " OK L${line} health" || echo " FAIL L${line} (${host})"
done
echo ""
echo "QR público:"
echo "  https://whatsapp.checkin24hs.com/api/qr"
echo "  https://whatsapp2.checkin24hs.com/api/qr"
echo "  https://whatsapp3.checkin24hs.com/api/qr"
echo "  https://whatsapp4.checkin24hs.com/api/qr"
echo "QR vía dashboard (funciona aunque Traefik falle):"
for line in 1 2 3 4; do
  echo "  https://dashboard.checkin24hs.com/api/whatsapp-qr/${line}"
done
