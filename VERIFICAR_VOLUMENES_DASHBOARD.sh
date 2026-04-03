#!/bin/bash
# Script para verificar cómo está montado el archivo dashboard.html

cd /root/checkin24hs

echo "=== VERIFICANDO CONFIGURACIÓN DE VOLÚMENES ==="
echo ""

# Obtener un contenedor activo
container=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$container" ]; then
    echo "No se encontraron contenedores"
    exit 1
fi

echo "Contenedor: $container"
echo ""

# Verificar montajes de volúmenes
echo "=== VOLÚMENES MONTADOS ==="
docker inspect $container | grep -A 10 "Mounts" | head -20
echo ""

# Verificar si el archivo está en un volumen
echo "=== VERIFICANDO ARCHIVO EN CONTENEDOR ==="
docker exec $container ls -lh /app/dashboard.html
echo ""

# Verificar línea 5150
echo "=== LÍNEA 5150 EN CONTENEDOR ==="
docker exec $container sed -n '5150p' /app/dashboard.html
echo ""

# Verificar si hay un volumen compartido
echo "=== VERIFICANDO SI HAY VOLÚMENES COMPARTIDOS ==="
docker volume ls | grep -i dashboard || echo "No se encontraron volúmenes específicos del dashboard"
echo ""

# Verificar configuración del servicio en docker-compose o stack
echo "=== VERIFICANDO CONFIGURACIÓN DEL SERVICIO ==="
docker inspect $container | grep -A 5 "com.docker.compose" || echo "No se encontró información de compose"








