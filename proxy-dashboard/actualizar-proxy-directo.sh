#!/bin/sh

# Script para actualizar el proxy con el nombre completo del contenedor activo

# Obtener el nombre completo del contenedor activo del dashboard
FULL_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$FULL_NAME" ]; then
    echo "Error: No se encontró ningún contenedor activo del dashboard."
    exit 1
fi

# Obtener el ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

if [ -z "$PROXY_CONTAINER_ID" ]; then
    echo "Error: No se encontró ningún contenedor activo del proxy."
    exit 1
fi

echo "Actualizando proxy $PROXY_CONTAINER_ID para apuntar a $FULL_NAME"

# Crear el contenido del archivo nginx.conf actualizado
cat > /tmp/nginx.conf <<EOF
# Resolver DNS de Docker (127.0.0.11)
# Este resolver permite resolución dinámica de nombres de contenedores
resolver 127.0.0.11 valid=10s ipv6=off;

server {
    listen 80;
    server_name localhost;

    location / {
        # Nombre del contenedor activo del dashboard
        set \$backend_upstream $FULL_NAME;
        
        # Proxy al contenedor del dashboard
        proxy_pass http://\$backend_upstream:3000;
        
        # Headers para el proxy
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
        
        # Manejo de errores
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_next_upstream_tries 1;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Copiar el archivo al contenedor
docker cp /tmp/nginx.conf $PROXY_CONTAINER_ID:/etc/nginx/conf.d/default.conf

# Verificar la sintaxis de la configuración de Nginx
docker exec $PROXY_CONTAINER_ID nginx -t

if [ $? -eq 0 ]; then
    # Recargar Nginx para aplicar los cambios
    docker exec $PROXY_CONTAINER_ID nginx -s reload
    echo "✅ Configuración de Nginx actualizada y recargada."
    echo "✅ Proxy apunta a: $FULL_NAME"
else
    echo "❌ Error: La configuración de Nginx tiene errores."
    exit 1
fi

# Limpiar archivo temporal
rm -f /tmp/nginx.conf
