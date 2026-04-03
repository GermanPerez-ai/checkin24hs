#!/bin/bash
# Script para verificar qué está sirviendo el dashboard realmente

echo "=========================================="
echo "VERIFICACIÓN DEL SERVIDOR DASHBOARD"
echo "=========================================="
echo ""

echo "1. Procesos Node.js corriendo:"
ps aux | grep node | grep -v grep
echo ""

echo "2. Contenedores Docker corriendo:"
docker ps | grep -i dashboard
echo ""

echo "3. Contenedores Docker (todos):"
docker ps -a | head -10
echo ""

echo "4. Proceso usando puerto 3000:"
sudo lsof -i :3000
echo ""

echo "5. Archivo dashboard.html que está sirviendo:"
curl -s http://localhost:3000/ | head -30 | grep -E "<title>|login|Ingresa tus credenciales"
echo ""

echo "6. Tamaño y fecha del dashboard.html en el servidor:"
ls -lh /root/checkin24hs/dashboard.html
echo ""

echo "7. PM2 procesos:"
pm2 list
echo ""

echo "8. Verificar si hay un servicio de EasyPanel corriendo:"
systemctl list-units --type=service | grep -i panel
echo ""

echo "9. Verificar si hay un proxy nginx o traefik:"
ps aux | grep -E "nginx|traefik" | grep -v grep
echo ""

echo "10. Verificar configuración de PM2 dashboard:"
pm2 describe dashboard | head -20


