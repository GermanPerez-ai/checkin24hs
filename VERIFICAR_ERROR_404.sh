#!/bin/bash
# Script para verificar por qué el dashboard devuelve 404

cd /root/checkin24hs

# Obtener un contenedor activo
container=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$container" ]; then
    echo "No se encontraron contenedores activos"
    exit 1
fi

echo "=== CONTENEDOR: $container ==="
echo ""

# Verificar qué proceso está corriendo
echo "=== PROCESOS ACTIVOS ==="
docker exec $container ps aux | head -10
echo ""

# Verificar si existe dashboard.html
echo "=== VERIFICANDO ARCHIVO dashboard.html ==="
docker exec $container ls -lh /app/dashboard.html 2>/dev/null || docker exec $container ls -lh /usr/share/nginx/html/dashboard.html 2>/dev/null || echo "Archivo no encontrado en /app ni en /usr/share/nginx/html"
echo ""

# Verificar estructura de directorios
echo "=== ESTRUCTURA DE DIRECTORIOS ==="
echo "Contenido de /app:"
docker exec $container ls -la /app 2>/dev/null | head -10 || echo "No existe /app"
echo ""
echo "Contenido de /usr/share/nginx/html:"
docker exec $container ls -la /usr/share/nginx/html 2>/dev/null | head -10 || echo "No existe /usr/share/nginx/html"
echo ""

# Verificar configuración de nginx (si existe)
echo "=== CONFIGURACIÓN NGINX ==="
docker exec $container cat /etc/nginx/conf.d/default.conf 2>/dev/null || echo "Nginx no configurado o no está usando Nginx"
echo ""

# Verificar logs del contenedor
echo "=== ÚLTIMOS LOGS DEL CONTENEDOR ==="
docker logs --tail 20 $container 2>&1 | tail -20
echo ""

# Verificar puerto y estado
echo "=== PUERTO Y ESTADO ==="
docker port $container
echo ""
docker inspect $container | grep -A 5 "State"








