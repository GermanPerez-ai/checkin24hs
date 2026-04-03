#!/bin/bash
# Recrear el servicio en la red easypanel

echo "=== 1. Obtener configuración actual ==="
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Host IP: $HOST_IP"

echo ""
echo "=== 2. Eliminar servicio actual ==="
docker service rm dashboard-proxy-service
sleep 3

echo ""
echo "=== 3. Crear nuevo servicio SOLO en la red easypanel ==="
docker service create \
  --name dashboard-proxy-service \
  --network easypanel \
  --mount type=bind,source=/tmp/dashboard-service-nginx.conf,target=/etc/nginx/conf.d/default.conf,readonly \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label "traefik.http.services.dashboard.loadbalancer.server.port=80" \
  --replicas 1 \
  nginx:alpine

if [ $? -eq 0 ]; then
    echo "✅ Servicio creado"
    
    echo ""
    echo "=== 4. Esperar 10 segundos ==="
    sleep 10
    
    echo ""
    echo "=== 5. Obtener VIP en la red easypanel ==="
    EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}')
    VIP=$(docker service inspect dashboard-proxy-service --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" | cut -d/ -f1)
    echo "VIP: $VIP"
    
    echo ""
    echo "=== 6. Probar acceso desde Traefik ==="
    docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=5 http://$VIP:80 2>&1 | head -5
    
    echo ""
    echo "=== 7. Si funciona, probar acceso al dashboard ==="
    sleep 5
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
else
    echo "❌ Error al crear el servicio"
fi

