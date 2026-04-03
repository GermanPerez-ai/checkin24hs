#!/bin/bash
# Diagnóstico CORS flor-api: comprobar si el 404 viene del backend o de Traefik.
# Ejecutar en el servidor: cd ~/checkin24hs && bash scripts/diagnostico_cors_flor_api.sh

set -e
cd "$(dirname "$0")/.."

echo "=== 1. OPTIONS vía Traefik (público) ==="
curl -sI -X OPTIONS -H "Origin: https://www.checkin24hs.com" https://flor-api.checkin24hs.com/api/flor/process 2>/dev/null | head -15

echo ""
echo "=== 2. OPTIONS directo al contenedor (misma red, sin Traefik) ==="
docker run --rm --network easypanel curlimages/curl:latest -sI -X OPTIONS -H "Origin: https://www.checkin24hs.com" http://checkin24hs_flor-api:8080/api/flor/process 2>/dev/null | head -15 || echo "(Falló: ¿red 'easypanel' existe? Listar: docker network ls | grep easypanel)"

echo ""
echo "=== 3. Servicio y red ==="
docker service inspect checkin24hs_flor-api --format '{{json .Endpoint.VirtualIPs}}' 2>/dev/null | head -3
echo ""
echo "Si (2) devuelve 204 y X-Flor-API:1, el backend está bien y el 404 viene de Traefik."
echo "Si (2) también devuelve 404, el request no está llegando bien al Node."
