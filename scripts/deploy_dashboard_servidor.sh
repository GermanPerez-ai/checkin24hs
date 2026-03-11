#!/bin/bash
# En el SERVIDOR: hace que dashboard.checkin24hs.com sirva exactamente lo que está en el repo (igual que tu local después de push).
# Uso: después de git push desde tu PC, conectate por SSH y ejecutá:
#   cd /root/checkin24hs && bash scripts/deploy_dashboard_servidor.sh
# O desde cualquier sitio: bash /root/checkin24hs/scripts/deploy_dashboard_servidor.sh

set -e
cd /root/checkin24hs

echo "=== 1. Actualizar repo desde GitHub ==="
git fetch origin
git reset --hard origin/main
git pull

# BUILD_ID desde el archivo del repo (quitar BOM/CRLF por si se editó en Windows)
BUILD_ID=$(cat deploy/dashboard-html/BUILD_ID 2>/dev/null | sed 's/^\xef\xbb\xbf//' | tr -d '\r\n\t ' | grep -oE '^[0-9]+$' || echo "79")
echo "BUILD_ID: $BUILD_ID"

echo ""
echo "=== 2. Construir imagen (sin caché) con tag fijo :$BUILD_ID (labels: quién/cuándo) ==="
docker build -f deploy/dashboard-html/Dockerfile \
  --build-arg BUILD_ID="$BUILD_ID" \
  --build-arg BUILD_SOURCE="deploy_dashboard_servidor.sh" \
  --build-arg BUILD_TIME="$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -t "easypanel/checkin24hs/dashboard:${BUILD_ID}" \
  -t easypanel/checkin24hs/dashboard:latest \
  --no-cache .

echo ""
echo "=== 3. Fijar el servicio a la imagen :$BUILD_ID (así nada que pise :latest te cambia el dashboard) ==="
SERVICE_NAME=$(docker service ls --format '{{.Name}}' 2>/dev/null | grep -E 'dashboard|checkin24hs.*dashboard' | head -1)
if [ -z "$SERVICE_NAME" ]; then
  SERVICE_NAME="checkin24hs_dashboard"
fi
echo "   Servicio: $SERVICE_NAME"
docker service update --force --image "easypanel/checkin24hs/dashboard:${BUILD_ID}" "$SERVICE_NAME"

echo ""
echo "=== Listo. Abrí https://dashboard.checkin24hs.com y recargá (Ctrl+Shift+R). Build esperado: $BUILD_ID ==="
