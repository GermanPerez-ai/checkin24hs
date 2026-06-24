#!/bin/bash
# Despliega WhatsApp Línea 2, 3 o 4 sin tocar las demás.
# Uso: cd /root/checkin24hs && bash scripts/deploy_whatsapp_linea_servidor.sh <2|3|4>
#
# DNS previo (mismo servidor que Línea 1):
#   whatsapp2.checkin24hs.com  → L2 (3002)
#   whatsapp3.checkin24hs.com  → L3 (3003)
#   whatsapp4.checkin24hs.com  → L4 (3004)

set -euo pipefail
cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

LINE="${1:-}"
if [[ ! "$LINE" =~ ^[234]$ ]]; then
  echo "Uso: bash scripts/deploy_whatsapp_linea_servidor.sh <2|3|4>"
  echo "  Línea 1: scripts/aplicar_traefik_whatsapp_servidor.sh checkin24hs_whatsapp"
  exit 1
fi

PORT=$((3000 + LINE))
HOST="whatsapp${LINE}.checkin24hs.com"
if [[ "$LINE" == "2" ]]; then
  HOST="whatsapp2.checkin24hs.com"
fi
SERVICE="checkin24hs_whatsapp${LINE}"
ROUTER="whatsapp${LINE}"
VOLUME="whatsapp${LINE}-auth"
IMAGE="easypanel/checkin24hs/whatsapp:latest"
NETWORK="easypanel"

echo "=== WhatsApp Línea $LINE — deploy ($HOST → puerto $PORT) ==="
git fetch origin main
git reset --hard origin/main
git pull origin main || true

echo "=== Build imagen whatsapp (compartida entre líneas) ==="
docker build -t "$IMAGE" "$REPO_ROOT/whatsapp-server"

TRAEFIK_LABEL_SPECS=(
  "traefik.enable=true"
  "traefik.docker.network=easypanel"
  "traefik.http.routers.${ROUTER}.rule=Host(\`${HOST}\`)"
  "traefik.http.routers.${ROUTER}.entrypoints=websecure"
  "traefik.http.routers.${ROUTER}.service=${ROUTER}"
  "traefik.http.routers.${ROUTER}.tls=true"
  "traefik.http.routers.${ROUTER}.tls.certresolver=letsencrypt"
  "traefik.http.routers.${ROUTER}.middlewares=whatsapp-cors,whatsapp-body"
  "traefik.http.routers.${ROUTER}.priority=100"
  "traefik.http.services.${ROUTER}.loadbalancer.server.port=${PORT}"
)

TRAEFIK_LABELS_CREATE=()
TRAEFIK_LABELS_UPDATE=()
for spec in "${TRAEFIK_LABEL_SPECS[@]}"; do
  TRAEFIK_LABELS_CREATE+=(--label "$spec")
  TRAEFIK_LABELS_UPDATE+=(--label-add "$spec")
done

if docker service inspect "$SERVICE" >/dev/null 2>&1; then
  echo "=== Actualizando servicio existente $SERVICE ==="
  docker service update \
    --image "$IMAGE" \
    --env-add "INSTANCE_NUMBER=${LINE}" \
    --env-add "PORT=${PORT}" \
    --update-order stop-first \
    --replicas 1 \
    "${TRAEFIK_LABELS_UPDATE[@]}" \
    "$SERVICE"
else
  echo "=== Creando servicio $SERVICE ==="
  docker service create \
    --name "$SERVICE" \
    --network "$NETWORK" \
    --replicas 1 \
    --mount "type=volume,source=${VOLUME},destination=/app/auth_info_baileys_${LINE}" \
    --env "INSTANCE_NUMBER=${LINE}" \
    --env "PORT=${PORT}" \
    "${TRAEFIK_LABELS_CREATE[@]}" \
    "$IMAGE"
fi

echo ""
echo "=== Verificación ==="
echo "Esperá ~30s y probá:"
echo "  curl -s https://${HOST}/api/status"
echo "  https://${HOST}/api/qr  (escaneá con el teléfono de Línea ${LINE})"
echo ""
echo "QR vía dashboard:"
echo "  https://dashboard.checkin24hs.com/api/whatsapp-qr/${LINE}"
echo ""
echo "Logs: docker service logs -f $SERVICE --tail 80"
