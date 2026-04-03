#!/bin/bash
# Agregar rutas NGINX al contenedor whatsapp-api

CONTENEDOR="checkin24hs_whatsapp-api.1.yuh9y9noygad9t40zt6is6rp1"
GATEWAY_IP="172.18.0.1"

# Modificar default.conf para agregar las rutas dentro del bloque server
docker exec $CONTENEDOR sh -c "cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    # Ruta 1: WhatsApp Instancia 1
    location /api1/ {
        proxy_pass http://${GATEWAY_IP}:4001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Ruta 2: WhatsApp Instancia 2
    location /api2/ {
        proxy_pass http://${GATEWAY_IP}:4002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Ruta 3: WhatsApp Instancia 3
    location /api3/ {
        proxy_pass http://${GATEWAY_IP}:4003/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Ruta 4: WhatsApp Instancia 4
    location /api4/ {
        proxy_pass http://${GATEWAY_IP}:4004/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Ruta por defecto
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF"

# Verificar configuración
echo "Verificando configuración NGINX..."
docker exec $CONTENEDOR nginx -t

# Recargar NGINX
echo "Recargando NGINX..."
docker exec $CONTENEDOR nginx -s reload

echo "✅ Rutas agregadas y NGINX recargado"


