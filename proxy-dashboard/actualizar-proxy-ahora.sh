#!/bin/bash

# Script para actualizar el proxy con el contenedor activo del dashboard

echo "🔍 Buscando contenedores..."

# Obtener el nombre del contenedor más reciente del dashboard
DASHBOARD_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$DASHBOARD_NAME" ]; then
    echo "❌ Error: No se encontró ningún contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor dashboard encontrado: $DASHBOARD_NAME"

# Obtener el ID del contenedor del proxy más reciente
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

if [ -z "$PROXY_ID" ]; then
    echo "❌ Error: No se encontró ningún contenedor del proxy"
    exit 1
fi

echo "✅ Contenedor proxy encontrado: $PROXY_ID"

# Crear el archivo nginx.conf
cat > /tmp/nginx.conf <<EOF
# Resolver DNS de Docker (127.0.0.11)
resolver 127.0.0.11 valid=10s ipv6=off;

server {
    listen 80;
    server_name localhost;

    location / {
        set \$backend_upstream $DASHBOARD_NAME;
        proxy_pass http://\$backend_upstream:3000;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        proxy_buffering off;
        proxy_request_buffering off;
        
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_next_upstream_tries 1;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo "📝 Copiando configuración al contenedor del proxy..."
docker cp /tmp/nginx.conf $PROXY_ID:/etc/nginx/conf.d/default.conf

echo "🔍 Verificando sintaxis de Nginx..."
docker exec $PROXY_ID nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Sintaxis correcta, recargando Nginx..."
    docker exec $PROXY_ID nginx -s reload
    echo ""
    echo "✅✅✅ Proxy actualizado correctamente ✅✅✅"
    echo "📊 Proxy apunta a: $DASHBOARD_NAME:3000"
    echo ""
    echo "🧪 Probando conexión..."
    docker exec $PROXY_ID wget -qO- http://localhost/health && echo "✅ Health check OK"
else
    echo "❌ Error: La configuración de Nginx tiene errores"
    rm -f /tmp/nginx.conf
    exit 1
fi

# Limpiar
rm -f /tmp/nginx.conf

echo ""
echo "🎉 ¡Listo! El proxy está actualizado y funcionando."
