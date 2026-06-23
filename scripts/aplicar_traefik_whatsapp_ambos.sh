#!/bin/bash
# Reaplica Traefik para Línea 1 y Línea 2 (404 en /api/qr, /api/status).
# Uso: cd /root/checkin24hs && bash scripts/aplicar_traefik_whatsapp_ambos.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Línea 1 (whatsapp.checkin24hs.com → puerto 3001) ==="
bash scripts/aplicar_traefik_whatsapp_servidor.sh checkin24hs_whatsapp

echo ""
echo "=== Línea 2 (whatsapp2.checkin24hs.com → puerto 3002) ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.whatsapp2.rule=Host(\`whatsapp2.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp2.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp2.service=whatsapp2" \
  --label-add "traefik.http.routers.whatsapp2.tls=true" \
  --label-add "traefik.http.routers.whatsapp2.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.whatsapp2.middlewares=whatsapp-cors,whatsapp-body" \
  --label-add "traefik.http.routers.whatsapp2.priority=100" \
  --label-add "traefik.http.services.whatsapp2.loadbalancer.server.port=3002" \
  checkin24hs_whatsapp2

echo ""
echo "=== Verificar (esperá ~20s) ==="
sleep 20
curl -sf https://whatsapp.checkin24hs.com/api/health && echo " OK L1 health" || echo " FAIL L1"
curl -sf https://whatsapp2.checkin24hs.com/api/health && echo " OK L2 health" || echo " FAIL L2"
echo ""
echo "QR público:"
echo "  https://whatsapp.checkin24hs.com/api/qr"
echo "  https://whatsapp2.checkin24hs.com/api/qr"
echo "QR vía dashboard (funciona aunque Traefik falle):"
echo "  https://dashboard.checkin24hs.com/api/whatsapp-qr/1"
echo "  https://dashboard.checkin24hs.com/api/whatsapp-qr/2"
