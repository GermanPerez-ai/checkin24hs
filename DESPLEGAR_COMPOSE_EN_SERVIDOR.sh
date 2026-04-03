#!/bin/bash
# Ejecutar EN EL SERVIDOR, en la carpeta del repo (donde está docker-compose.easypanel.yml).
# Crea la red easypanel si no existe y levanta el stack (dashboard, whatsapp, cotizador, webmail).

set -e
cd "$(dirname "$0")"

echo "Red easypanel..."
docker network inspect easypanel >/dev/null 2>&1 || docker network create easypanel

echo "Levantando stack (dashboard, whatsapp, cotizador, webmail)..."
docker compose -f docker-compose.easypanel.yml up -d --build

echo ""
echo "Contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "dashboard|whatsapp|cotizador|webmail" || true

echo ""
echo "En 1-2 min probá: https://dashboard.checkin24hs.com/"
