#!/bin/bash
# Script para verificar que el banner esté en el archivo del contenedor

cd /root/checkin24hs

container=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$container" ]; then
    echo "No se encontraron contenedores activos"
    exit 1
fi

echo "=== CONTENEDOR: $container ==="
echo ""

# Verificar si existe el banner en el archivo
echo "=== VERIFICANDO BANNER whatsapp-no-url-alert ==="
docker exec $container grep -n "whatsapp-no-url-alert" /app/dashboard.html | head -3
echo ""

# Verificar si existe la función updateWhatsAppServerStatus con logs
echo "=== VERIFICANDO FUNCIÓN updateWhatsAppServerStatus ==="
docker exec $container grep -n "updateWhatsAppServerStatus llamada" /app/dashboard.html | head -1
echo ""

# Verificar tamaño del archivo
echo "=== TAMAÑO DEL ARCHIVO ==="
docker exec $container ls -lh /app/dashboard.html
echo ""

# Verificar fecha del archivo
echo "=== FECHA DEL ARCHIVO ==="
docker exec $container stat -c %y /app/dashboard.html 2>/dev/null || docker exec $container stat -f %Sm /app/dashboard.html 2>/dev/null








