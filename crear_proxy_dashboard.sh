#!/bin/bash
# Crear contenedor Nginx que haga proxy al puerto 3000

echo "=== Crear contenedor Nginx para proxy al puerto 3000 ==="

# Obtener la IP del host en la red Docker
HOST_IP=$(docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "172.17.0.1")

echo "IP del host detectada: $HOST_IP"

# Crear configuración Nginx
cat > /tmp/dashboard-nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://host.docker.internal:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Crear contenedor
docker run -d \
  --name dashboard-nginx-proxy \
  --network easypanel \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.services.dashboard.loadbalancer.server.port=80" \
  --restart unless-stopped \
  -v /tmp/dashboard-nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:alpine

if [ $? -eq 0 ]; then
    echo "✅ Contenedor creado"
    echo ""
    echo "=== Verificar ==="
    docker ps | grep dashboard-nginx-proxy
    echo ""
    echo "=== Logs ==="
    docker logs dashboard-nginx-proxy --tail 10
else
    echo "⚠️  Error al crear contenedor. Intentando con IP del host..."
    
    # Si host.docker.internal no funciona, usar la IP del gateway
    sed "s/host.docker.internal/$HOST_IP/g" /tmp/dashboard-nginx.conf > /tmp/dashboard-nginx-ip.conf
    
    docker run -d \
      --name dashboard-nginx-proxy \
      --network easypanel \
      --label "traefik.enable=true" \
      --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label "traefik.http.routers.dashboard.entrypoints=web" \
      --label "traefik.http.services.dashboard.loadbalancer.server.port=80" \
      --restart unless-stopped \
      -v /tmp/dashboard-nginx-ip.conf:/etc/nginx/conf.d/default.conf:ro \
      nginx:alpine
    
    if [ $? -eq 0 ]; then
        echo "✅ Contenedor creado con IP del host"
    fi
fi

echo ""
echo "=== Limpiar archivos temporales ==="
rm -f /tmp/dashboard-nginx.conf /tmp/dashboard-nginx-ip.conf

echo ""
echo "✅ Configuración completada!"
echo "El dashboard debería estar accesible en: http://dashboard.checkin24hs.com"

