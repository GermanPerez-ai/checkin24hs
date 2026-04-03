#!/bin/bash
# Recrear contenedor con la configuración correcta

ETH0_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

echo "=== Detener y eliminar contenedor actual ==="
docker stop dashboard-nginx-proxy
docker rm dashboard-nginx-proxy

echo ""
echo "=== Crear nueva configuración con IP: $ETH0_IP ==="
cat > /tmp/dashboard-nginx.conf << EOF
server {
    listen 80;
    location / {
        proxy_pass http://$ETH0_IP:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo "✅ Configuración creada"

echo ""
echo "=== Crear nuevo contenedor ==="
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
    echo "=== Esperar 3 segundos ==="
    sleep 3
    
    echo ""
    echo "=== Verificar estado ==="
    docker ps | grep dashboard-nginx-proxy
    
    echo ""
    echo "=== Probar acceso ==="
    docker exec dashboard-nginx-proxy wget -qO- http://localhost/ 2>&1 | head -5
    
    echo ""
    echo "✅ Si ves HTML, el proxy está funcionando!"
    echo "El dashboard debería estar accesible en: http://dashboard.checkin24hs.com"
else
    echo "❌ Error al crear contenedor"
fi

