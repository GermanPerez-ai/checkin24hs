#!/bin/bash
# Diagnosticar por qué el proxy no funciona

echo "=== 1. Ver configuración de Nginx ==="
docker exec dashboard-nginx-proxy cat /etc/nginx/conf.d/default.conf

echo ""
echo "=== 2. Ver logs de error de Nginx ==="
docker logs dashboard-nginx-proxy 2>&1 | grep -i error | tail -10

echo ""
echo "=== 3. Probar acceso directo al puerto 3000 desde el contenedor ==="
docker exec dashboard-nginx-proxy wget -qO- --timeout=3 http://10.11.0.1:3000 2>&1 | head -5

echo ""
echo "=== 4. Verificar que Nginx esté escuchando ==="
docker exec dashboard-nginx-proxy netstat -tuln | grep 80 || docker exec dashboard-nginx-proxy ss -tuln | grep 80

echo ""
echo "=== 5. Verificar conectividad ==="
docker exec dashboard-nginx-proxy ping -c 1 10.11.0.1

