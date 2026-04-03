#!/bin/bash
# Verificar qué ruta usa el servidor web para servir dashboard.html

cd /root/checkin24hs

echo "=========================================="
echo "Verificando configuración del servidor web"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "No se encontraron contenedores"
    exit 1
fi

echo "Usando contenedor: $CONTAINER"
echo ""

# Verificar si es nginx
if docker exec "$CONTAINER" which nginx >/dev/null 2>&1; then
    echo "Servidor: Nginx"
    echo ""
    echo "Buscando configuración de nginx..."
    docker exec "$CONTAINER" find /etc/nginx -name "*.conf" -type f 2>/dev/null | head -5
    echo ""
    echo "Verificando ruta root en nginx.conf:"
    docker exec "$CONTAINER" grep -i "root\|index" /etc/nginx/nginx.conf 2>/dev/null | head -10
    echo ""
    echo "Buscando configuración de servidor..."
    docker exec "$CONTAINER" find /etc/nginx -type f -exec grep -l "dashboard.html\|root" {} \; 2>/dev/null | head -3
fi

# Verificar si es apache
if docker exec "$CONTAINER" which httpd >/dev/null 2>&1 || docker exec "$CONTAINER" which apache2 >/dev/null 2>&1; then
    echo "Servidor: Apache"
    echo ""
    echo "Buscando configuración de apache..."
    docker exec "$CONTAINER" find /etc/apache2 /etc/httpd -name "*.conf" -type f 2>/dev/null | head -5
fi

# Verificar qué archivo está sirviendo realmente
echo ""
echo "Archivos dashboard.html encontrados en el contenedor:"
docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | while read file; do
    echo "  - $file"
    echo "    Tamaño: $(docker exec "$CONTAINER" ls -lh "$file" 2>/dev/null | awk '{print $5}')"
    echo "    Tags <html>: $(docker exec "$CONTAINER" grep -c '<html' "$file" 2>/dev/null || echo "0")"
done


