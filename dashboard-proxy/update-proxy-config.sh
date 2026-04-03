#!/bin/bash
# Script para actualizar la configuración del proxy nginx con el nombre del contenedor actual del dashboard

# Obtener el nombre del contenedor activo del dashboard
CONTAINER_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ Error: No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_NAME"

# Crear configuración de nginx actualizada
cat > nginx.conf << EOF
# Configuración de Nginx Proxy para Dashboard
# Actualizada automáticamente - Contenedor: $CONTAINER_NAME

upstream dashboard_backend {
    server $CONTAINER_NAME:3000;
    resolver 127.0.0.11 valid=10s ipv6=off;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://dashboard_backend;
        proxy_http_version 1.1;
        
        # Headers para el proxy
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
        
        # No cachear respuestas
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
}
EOF

echo "✅ Configuración actualizada en nginx.conf"
