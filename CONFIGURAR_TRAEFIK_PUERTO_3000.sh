#!/bin/bash
# Configurar Traefik para que apunte al puerto 3000

echo "=== Ver configuración actual de Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g cat /etc/traefik/traefik.yml 2>/dev/null || echo "No se puede acceder"

echo ""
echo "=== Crear servicio Docker simple para Traefik ==="
echo "Este servicio hará que Traefik detecte y enrute el tráfico al puerto 3000"

# Crear un servicio Docker simple que Traefik pueda detectar
docker service create \
  --name dashboard-proxy \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --network easypanel \
  --mode global \
  --constraint "node.hostname==$(hostname)" \
  --mount type=bind,source=/proc,target=/proc,readonly \
  --mount type=bind,source=/sys,target=/sys,readonly \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
  nginx:alpine \
  sh -c "while true; do sleep 3600; done" 2>/dev/null

if [ $? -ne 0 ]; then
    echo ""
    echo "⚠️  El servicio ya existe o hay un error. Intentando otra solución..."
    echo ""
    echo "=== Solución alternativa: Configurar Traefik con archivo estático ==="
    echo "Necesitamos crear un archivo de configuración para Traefik"
fi

