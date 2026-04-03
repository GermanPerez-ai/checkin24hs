#!/bin/bash
# Script para agregar rutas NGINX al contenedor

CONTENEDOR="checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm"

# Crear archivo de configuración con las rutas
docker exec $CONTENEDOR sh -c 'cat > /etc/nginx/conf.d/rutas.conf << "EOF"
# Ruta 1: WhatsApp Instancia 1
location /api1/ {
    proxy_pass http://host.docker.internal:4001/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Ruta 2: WhatsApp Instancia 2
location /api2/ {
    proxy_pass http://host.docker.internal:4002/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Ruta 3: WhatsApp Instancia 3
location /api3/ {
    proxy_pass http://host.docker.internal:4003/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Ruta 4: WhatsApp Instancia 4
location /api4/ {
    proxy_pass http://host.docker.internal:4004/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}
EOF'

# Verificar que el archivo se creó
echo "Verificando archivo creado..."
docker exec $CONTENEDOR cat /etc/nginx/conf.d/rutas.conf

# Recargar NGINX
echo "Recargando NGINX..."
docker exec $CONTENEDOR nginx -s reload

echo "✅ Rutas agregadas y NGINX recargado"


