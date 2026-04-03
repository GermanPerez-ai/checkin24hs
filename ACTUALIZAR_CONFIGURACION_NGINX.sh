#!/bin/bash
# Actualizar configuración de Nginx con la IP correcta

ETH0_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

echo "=== Actualizando configuración con IP: $ETH0_IP ==="

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

echo "✅ Configuración actualizada"

echo ""
echo "=== Reiniciar contenedor ==="
docker restart dashboard-nginx-proxy

echo ""
echo "=== Esperar 3 segundos ==="
sleep 3

echo ""
echo "=== Probar acceso desde el contenedor ==="
docker exec dashboard-nginx-proxy wget -qO- http://localhost/ 2>&1 | head -5

echo ""
echo "✅ Si ves HTML, el proxy está funcionando!"
echo "El dashboard debería estar accesible en: http://dashboard.checkin24hs.com"

