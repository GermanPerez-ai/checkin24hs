#!/bin/bash
# Crear servicio Docker Swarm que apunte directamente al puerto 3000

echo "=== Obtener IP del gateway de la red Docker ==="
GATEWAY_IP=$(docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
echo "Gateway IP: $GATEWAY_IP"

echo ""
echo "=== Crear servicio que apunte directamente al puerto 3000 ==="
docker service create \
  --name dashboard-proxy-service \
  --network easypanel \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label "traefik.http.services.dashboard.loadbalancer.server=http://$GATEWAY_IP:3000" \
  --replicas 1 \
  nginx:alpine \
  sh -c "while true; do sleep 3600; done"

if [ $? -eq 0 ]; then
    echo "✅ Servicio creado"
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ Error al crear el servicio"
    echo ""
    echo "=== Alternativa: Usar host.docker.internal ==="
    docker service create \
      --name dashboard-proxy-service \
      --network easypanel \
      --label "traefik.enable=true" \
      --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label "traefik.http.routers.dashboard.entrypoints=web" \
      --label "traefik.http.routers.dashboard.entrypoints=websecure" \
      --label "traefik.http.services.dashboard.loadbalancer.server=http://host.docker.internal:3000" \
      --replicas 1 \
      nginx:alpine \
      sh -c "while true; do sleep 3600; done"
fi

