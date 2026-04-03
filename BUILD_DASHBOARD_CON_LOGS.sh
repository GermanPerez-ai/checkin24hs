#!/bin/bash
# Build del dashboard con logs claros de inicio y fin.
# Ejecutar en el servidor: ./BUILD_DASHBOARD_CON_LOGS.sh

set -e
cd "$(dirname "$0")"

echo ""
echo "=============================================="
echo "  $(date '+%Y-%m-%d %H:%M:%S') - INICIANDO BUILD DASHBOARD"
echo "=============================================="
echo ""

# Build number que tiene el archivo actual (para referencia)
BUILD_NUM=$(grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' dashboard.html 2>/dev/null | grep -o '[0-9]*' || echo "?")
echo "  Build en dashboard.html: #$BUILD_NUM"
echo ""

echo "--- 1/4 git pull ---"
git pull
echo ""

echo "--- 2/4 Construyendo imagen (sin caché) ---"
docker build --no-cache -f deploy/dashboard-html/Dockerfile -t easypanel/checkin24hs/dashboard:latest .
echo ""

echo "--- 3/4 Imagen construida. Actualizando servicio Swarm ---"
docker service update --force --image easypanel/checkin24hs/dashboard:latest checkin24hs_dashboard
echo ""

echo "=============================================="
echo "  $(date '+%Y-%m-%d %H:%M:%S') - BUILD FINALIZADO"
echo "=============================================="
echo ""
echo "  Probar en 1-2 min: https://dashboard.checkin24hs.com/"
echo "  (incógnito o Ctrl+Shift+R)"
echo ""
