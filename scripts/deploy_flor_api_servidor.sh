#!/bin/bash
# Despliega la API Flor para la web (flor-api.checkin24hs.com) por git.
# Uso: cd /root/checkin24hs && bash scripts/deploy_flor_api_servidor.sh
#
# Primera vez: si el servicio no existe, crealo desde EasyPanel (Redeploy from Compose)
# o con: docker stack deploy -c docker-compose.easypanel.yml checkin24hs
# (solo si tu stack acepta redeploy; si da "already exists", usá EasyPanel una vez para crear flor-api)

set -e
cd /root/checkin24hs

echo "=== 1. Actualizar repo ==="
git fetch origin
git reset --hard origin/main
git pull origin main

echo ""
echo "=== 2. Construir imagen flor-api ==="
docker compose -f docker-compose.easypanel.yml build --no-cache flor-api

echo ""
echo "=== 3. Actualizar servicio Swarm ==="
SVC="checkin24hs_flor-api"
if docker service ls --format '{{.Name}}' 2>/dev/null | grep -q "^${SVC}$"; then
  echo "Actualizando ${SVC}..."
  docker service update --image easypanel/checkin24hs/flor-api:latest --force "$SVC"
  echo ""
  echo "=== Listo. Probá https://flor-api.checkin24hs.com/health ==="
else
  echo "Servicio ${SVC} no existe."
  echo "Crealo una vez desde EasyPanel (Redeploy from Compose) o ejecutando:"
  echo "  docker stack deploy -c docker-compose.easypanel.yml checkin24hs"
  echo "Luego volvé a correr este script."
  exit 1
fi
