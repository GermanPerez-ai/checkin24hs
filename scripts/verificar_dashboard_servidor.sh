#!/bin/bash
# En el SERVIDOR: verifica qué está sirviendo el dashboard (imagen, build, labels).
# Uso: bash /root/checkin24hs/scripts/verificar_dashboard_servidor.sh

cd /root/checkin24hs 2>/dev/null || true

SERVICE_NAME="checkin24hs_dashboard"
EXPECTED_BUILD=$(cat deploy/dashboard-html/BUILD_ID 2>/dev/null || echo "?")

echo "=== Verificación dashboard en servidor ==="
echo ""

echo "1. Imagen que usa el servicio:"
docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || echo "(error)"
echo ""

echo "2. Build que sirve la URL (build_id.txt):"
curl -sS --max-time 5 https://dashboard.checkin24hs.com/build_id.txt 2>/dev/null || echo "(error)"
echo ""

echo "3. Build esperado en el repo: $EXPECTED_BUILD"
echo ""

echo "4. ¿Quién construyó la imagen actual?"
IMAGE_REF=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)
if [ -n "$IMAGE_REF" ]; then
  BUILD_SOURCE=$(docker image inspect "$IMAGE_REF" --format '{{index .Config.Labels "checkin24hs.build_source"}}' 2>/dev/null || echo "")
  if [ -n "$BUILD_SOURCE" ]; then
    echo "   Construido por: $BUILD_SOURCE"
  else
    echo "   Construido por: (otro proceso, no nuestro script)"
  fi
else
  echo "   (no se pudo inspeccionar)"
fi
echo ""

echo "=== Si build en vivo no es $EXPECTED_BUILD, ejecutá: bash scripts/deploy_dashboard_servidor.sh ==="
