#!/bin/bash
# Despliega WhatsApp Línea 2 (INSTANCE_NUMBER=2) sin tocar Línea 1.
# Requisitos: DNS whatsapp2.checkin24hs.com → este servidor, red easypanel, Traefik activo.
# Uso en servidor: cd /root/checkin24hs && bash scripts/deploy_whatsapp2_servidor.sh

set -euo pipefail
cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

echo "=== WhatsApp Línea 2 — deploy ==="
git fetch origin main
git reset --hard origin/main
git pull origin main || true

echo "=== Build imagen whatsapp (compartida con Línea 1) ==="
docker build -t easypanel/checkin24hs/whatsapp:latest "$REPO_ROOT/whatsapp-server"

SERVICE="checkin24hs_whatsapp2"
IMAGE="easypanel/checkin24hs/whatsapp:latest"
NETWORK="easypanel"
VOLUME="whatsapp2-auth"

TRAEFIK_LABELS=(
  --label-add "traefik.enable=true"
  --label-add "traefik.docker.network=easypanel"
  --label-add "traefik.http.routers.whatsapp2.rule=Host(\`whatsapp2.checkin24hs.com\`)"
  --label-add "traefik.http.routers.whatsapp2.entrypoints=websecure"
  --label-add "traefik.http.routers.whatsapp2.service=whatsapp2"
  --label-add "traefik.http.routers.whatsapp2.tls=true"
  --label-add "traefik.http.routers.whatsapp2.tls.certresolver=letsencrypt"
  --label-add "traefik.http.routers.whatsapp2.middlewares=whatsapp-cors,whatsapp-body"
  --label-add "traefik.http.routers.whatsapp2.priority=100"
  --label-add "traefik.http.services.whatsapp2.loadbalancer.server.port=3002"
)

if docker service inspect "$SERVICE" >/dev/null 2>&1; then
  echo "=== Actualizando servicio existente $SERVICE ==="
  docker service update \
    --image "$IMAGE" \
    --env-add INSTANCE_NUMBER=2 \
    --env-add PORT=3002 \
    --update-order stop-first \
    --replicas 1 \
    "${TRAEFIK_LABELS[@]}" \
    "$SERVICE"
else
  echo "=== Creando servicio $SERVICE ==="
  docker service create \
    --name "$SERVICE" \
    --network "$NETWORK" \
    --replicas 1 \
    --mount "type=volume,source=${VOLUME},destination=/app/auth_info_baileys_2" \
    --env INSTANCE_NUMBER=2 \
    --env PORT=3002 \
    "${TRAEFIK_LABELS[@]}" \
    "$IMAGE"
fi

echo ""
echo "=== Verificación ==="
echo "Esperá ~30s y probá:"
echo "  curl -s https://whatsapp2.checkin24hs.com/api/status"
echo "  https://whatsapp2.checkin24hs.com/api/qr  (escaneá con el SEGUNDO teléfono)"
echo ""
echo "Logs: docker service logs -f $SERVICE --tail 80"
