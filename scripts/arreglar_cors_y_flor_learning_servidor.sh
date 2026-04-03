#!/bin/bash
# Arregla CORS en flor-api y actualiza la web con flor-learning-system sin response_length.
# Ejecutar en el servidor: cd ~/checkin24hs && bash scripts/arreglar_cors_y_flor_learning_servidor.sh
#
# Requiere: git pull ya hecho (o ejecutar aquí), docker, acceso a la red easypanel.

set -e
cd "$(dirname "$0")/.."

echo "=== 0. Actualizar repo ==="
git pull || true

echo ""
echo "=== 1. CORS en flor-api (Traefik) ==="
docker service update \
  --label-add "traefik.http.routers.florapi.middlewares=florapi-cors" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolallowmethods=GET,POST,OPTIONS" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolallowheaders=Content-Type,Authorization,Accept" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolalloworiginlist=https://www.checkin24hs.com,https://checkin24hs.com" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolmaxage=86400" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.addvaryheader=true" \
  checkin24hs_flor-api 2>/dev/null || echo "(Omitido si el servicio no existe o ya tiene los labels)"

echo ""
echo "=== 2. Build web desde checkin24hs-web (flor-chatbot v3.0.1, flor-learning sin response_length) ==="
docker build -t easypanel/checkin24hs/web:latest ./checkin24hs-web

echo ""
echo "=== 3. Actualizar servicios que pueden servir www ==="
docker service update --image easypanel/checkin24hs/web:latest checkin24hs_web 2>/dev/null || true
docker service update --image easypanel/checkin24hs/web:latest checkin24hs_appwebcheckin24hs 2>/dev/null || true

echo ""
echo "=== Listo. Probar en incógnito: https://www.checkin24hs.com y abrir el chat Flor. ==="
echo "  - CORS: no debería aparecer bloqueo a flor-api.checkin24hs.com"
echo "  - En Network/Consola: flor-learning-system.js debería cargar con ?v=3.0.1 y no error response_length"
