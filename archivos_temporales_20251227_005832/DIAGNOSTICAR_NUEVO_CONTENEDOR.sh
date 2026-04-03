#!/bin/bash
# Diagnosticar el nuevo contenedor

echo "=== 1. Ver logs del contenedor ==="
docker logs dashboard-nginx-proxy --tail 20

echo ""
echo "=== 2. Verificar configuración dentro del contenedor ==="
docker exec dashboard-nginx-proxy cat /etc/nginx/conf.d/default.conf

echo ""
echo "=== 3. Verificar que Nginx esté corriendo ==="
docker exec dashboard-nginx-proxy ps aux | grep nginx

echo ""
echo "=== 4. Probar acceso directo al puerto 3000 desde el contenedor ==="
ETH0_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
docker exec dashboard-nginx-proxy wget -qO- --timeout=3 http://$ETH0_IP:3000 2>&1 | head -3

echo ""
echo "=== 5. Verificar que el puerto 80 esté escuchando en el contenedor ==="
docker exec dashboard-nginx-proxy netstat -tuln | grep 80 || docker exec dashboard-nginx-proxy ss -tuln | grep 80

