#!/bin/bash

# Script para actualizar el proxy con la IP directa del contenedor activo del dashboard

echo "🔍 Buscando contenedor activo del dashboard..."

# Obtener el ID y la IP del contenedor más reciente del dashboard
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_ID" ]; then
    echo "❌ Error: No se encontró ningún contenedor del dashboard"
    exit 1
fi

DASHBOARD_IP=$(docker inspect $DASHBOARD_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)

if [ -z "$DASHBOARD_IP" ]; then
    echo "❌ Error: No se pudo obtener la IP del contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor dashboard encontrado: $DASHBOARD_ID"
echo "✅ IP del dashboard: $DASHBOARD_IP"

# Obtener el ID del contenedor del proxy más reciente
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

if [ -z "$PROXY_ID" ]; then
    echo "❌ Error: No se encontró ningún contenedor del proxy"
    exit 1
fi

echo "✅ Contenedor proxy encontrado: $PROXY_ID"

# Crear el archivo nginx.conf usando la IP directa
cat > /tmp/nginx.conf <<EOF
# Resolver DNS de Docker (127.0.0.11)
resolver 127.0.0.11 valid=10s ipv6=off;

server {
    listen 80;
    server_name localhost;

    location / {
        # Usar la IP directa del contenedor activo del dashboard
        proxy_pass http://$DASHBOARD_IP:3000;
        
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
    echo "📊 Proxy apunta a: $DASHBOARD_IP:3000"
    echo ""
    echo "🧪 Probando conexión..."
    docker exec $PROXY_ID wget -qO- http://$DASHBOARD_IP:3000/health && echo "✅ Conexión OK"
else
    echo "❌ Error: La configuración de Nginx tiene errores"
    rm -f /tmp/nginx.conf
    exit 1
fi

# Limpiar
rm -f /tmp/nginx.conf

echo ""
echo "🎉 ¡Listo! El proxy está actualizado y funcionando."
echo ""
echo "⚠️  NOTA: Si el contenedor del dashboard se recrea, ejecuta este script nuevamente"
echo "   para actualizar la IP en el proxy."
