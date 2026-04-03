#!/bin/bash
# En el SERVIDOR: detecta qué imagen está sirviendo el dashboard y quién/cuándo la construyó.
# Uso: bash /root/checkin24hs/scripts/detectar_quien_construyo_dashboard.sh
# Opcional: DASHBOARD_URL=https://dashboard.checkin24hs.com (por defecto)

set -e
REPO_DIR="${REPO_DIR:-/root/checkin24hs}"
cd "$REPO_DIR" 2>/dev/null || true

SERVICE_NAME="${SERVICE_NAME:-checkin24hs_dashboard}"
DASHBOARD_URL="${DASHBOARD_URL:-https://dashboard.checkin24hs.com}"
EXPECTED_BUILD_ID=$(cat deploy/dashboard-html/BUILD_ID 2>/dev/null || echo "?")

echo "=============================================="
echo "  Dashboard: qué imagen corre y quién la construyó"
echo "=============================================="
echo ""

# 1. Imagen que usa el servicio
IMAGE_REF=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || echo "")
if [ -z "$IMAGE_REF" ]; then
  echo "No se pudo obtener la imagen del servicio $SERVICE_NAME (¿existe el servicio?)."
  exit 1
fi
echo "Servicio: $SERVICE_NAME"
echo "Imagen en uso: $IMAGE_REF"
echo ""

# 2. Inspeccionar la imagen (labels = quién/cuándo construyó)
echo "--- Labels de la imagen (quién/cuándo se construyó) ---"
docker image inspect "$IMAGE_REF" --format '{{range $k, $v := .Config.Labels}}{{$k}}={{$v}}
{{end}}' 2>/dev/null | grep -E "checkin24hs\.(build_source|build_time)" || echo "(ninguna label checkin24hs.*)"
echo ""

# Formato legible
BUILD_SOURCE=$(docker image inspect "$IMAGE_REF" --format '{{index .Config.Labels "checkin24hs.build_source"}}' 2>/dev/null || echo "")
BUILD_TIME=$(docker image inspect "$IMAGE_REF" --format '{{index .Config.Labels "checkin24hs.build_time"}}' 2>/dev/null || echo "")
CREATED_AT=$(docker image inspect "$IMAGE_REF" --format '{{.Created}}' 2>/dev/null || echo "")

if [ -n "$BUILD_SOURCE" ]; then
  echo "Construido por (label): $BUILD_SOURCE"
  echo "Construido cuando (label): $BUILD_TIME"
else
  echo "Construido por (label): (no tiene label checkin24hs.build_source → no fue nuestro script)"
fi
echo "Fecha de la imagen (Docker): $CREATED_AT"
echo ""

# 3. Build ID que sirve la URL (lo que ve el usuario)
echo "--- Build que sirve la URL $DASHBOARD_URL ---"
LIVE_BUILD=$(curl -sS --max-time 5 "${DASHBOARD_URL}/build_id.txt" 2>/dev/null || echo "")
if [ -n "$LIVE_BUILD" ]; then
  echo "build_id.txt en vivo: $LIVE_BUILD"
  echo "BUILD_ID esperado (repo): $EXPECTED_BUILD_ID"
  if [ "$LIVE_BUILD" != "$EXPECTED_BUILD_ID" ]; then
    echo ""
    echo ">>> DETECTADO: La URL sirve build $LIVE_BUILD pero el repo espera $EXPECTED_BUILD_ID."
    echo "    Algo reemplazó la imagen (EasyPanel, cron, etc.). Ejecutá: bash scripts/deploy_dashboard_servidor.sh"
  fi
else
  echo "(no se pudo obtener build_id.txt desde la URL)"
fi
echo ""
echo "=============================================="
