#!/bin/bash
# Actualiza ANA (ana.checkin24hs.com) con lo que está en origin/main.
# No toca WhatsApp ni el dashboard.
set -e
cd /root/checkin24hs

echo "=== 1. Repo ==="
git fetch origin
if ! git pull origin main; then
  BAK="/root/backups/ana-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BAK"
  echo "   git pull chocó: aparto ana/ local a $BAK"
  [ -e ana ] && mv ana "$BAK/"
  [ -e docker-compose.ana.yml ] && mv docker-compose.ana.yml "$BAK/"
  git pull origin main
fi
git checkout origin/main -- ana docker-compose.ana.yml
test -f ana/Dockerfile
test -f ana/public/index.html

echo "=== 2. Imagen ANA ==="
docker build -f ana/Dockerfile -t easypanel/checkin24hs/ana:latest ./ana

echo "=== 3. Servicio ==="
SVC=$(docker service ls --format '{{.Name}}' 2>/dev/null | grep -E '(^|_)ana($|_)' | head -1)
if [ -z "$SVC" ]; then
  SVC=$(docker service ls --format '{{.Name}}' 2>/dev/null | grep -i ana | grep -vi whatsapp | head -1)
fi
if [ -n "$SVC" ]; then
  echo "   Swarm: $SVC"
  docker service update --force --image easypanel/checkin24hs/ana:latest "$SVC"
else
  echo "   Compose (no hay service Swarm de ANA)"
  docker compose -f docker-compose.ana.yml up -d --force-recreate
fi

echo ""
echo "=== Comprobar HTML ==="
sleep 8
curl -sS -k https://ana.checkin24hs.com/ | grep -o "Pedido de anulación" | head -1 || echo "(todavía no aparece: esperá 15s y recargá con Ctrl+Shift+R)"
echo "Listo."
