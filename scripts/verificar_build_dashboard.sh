#!/bin/bash
# Verificar por qué el dashboard puede seguir mostrando Build #82 en lugar de #83.
# Ejecutar en el servidor: bash scripts/verificar_build_dashboard.sh

set -e
cd "$(dirname "$0")/.."

echo "=== 1. BUILD_ID en archivo del repo ==="
cat deploy/dashboard-html/BUILD_ID 2>/dev/null || echo "(no existe)"
echo ""

echo "=== 2. DASHBOARD_BUILD_NUMBER en deploy/dashboard.html (fuente del Dockerfile) ==="
grep -n "DASHBOARD_BUILD_NUMBER" deploy/dashboard.html | head -3
echo ""

echo "=== 3. Imagen actual del servicio checkin24hs_dashboard ==="
IMG=$(docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null || echo "(servicio no encontrado)")
echo "Imagen: $IMG"
echo ""

echo "=== 4. Contenido dentro de la imagen (qué BUILD_NUMBER tiene el HTML empaquetado) ==="
# Ejecutar un contenedor temporal y leer la variable del HTML
docker run --rm "$IMG" grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*" /app/dashboard.html 2>/dev/null || echo "(no se pudo leer; imagen sin /app/dashboard.html?)"
echo ""

echo "=== 5. build_id.txt dentro de la imagen ==="
docker run --rm "$IMG" cat /app/build_id.txt 2>/dev/null || echo "(no existe)"
echo ""

echo "=== Resumen ==="
echo "Si en (2) sale 83 pero en (4) sale 82: la imagen que está corriendo es vieja. Ejecutá:"
echo "  git pull origin main"
echo "  bash scripts/deploy_dashboard_servidor.sh"
echo "Si en (2) sale 82: los cambios no están en el repo del servidor. Hacé push desde tu PC y luego git pull en el servidor."
