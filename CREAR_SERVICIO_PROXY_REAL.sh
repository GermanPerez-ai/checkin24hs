#!/bin/bash
# Crear un servicio Swarm que sea un proxy real apuntando al puerto 3000

echo "=== Obtener IP pública del host ==="
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Host IP: $HOST_IP"

echo ""
echo "=== Crear configuración Nginx para el servicio ==="
cat > /tmp/dashboard-service-nginx.conf << EOF
server {
    listen 80;
    location / {
        proxy_pass http://$HOST_IP:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo "✅ Configuración creada"

echo ""
echo "=== Eliminar servicio anterior ==="
docker service rm dashboard-proxy-service 2>/dev/null
sleep 3

echo ""
echo "=== Crear nuevo servicio con Nginx como proxy real ==="
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
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "=== Probar acceso ==="
    curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
    
    echo ""
    echo "=== Probar HTTP ==="
    curl -L http://dashboard.checkin24hs.com 2>&1 | head -5
else
    echo "❌ Error al crear el servicio"
fi

