#!/bin/bash
# Diagnosticar error de Nginx

echo "=== Ver error completo de Nginx ==="
sudo systemctl status nginx.service --no-pager -l

echo ""
echo "=== Ver logs del sistema ==="
sudo journalctl -xeu nginx.service --no-pager | tail -20

echo ""
echo "=== Verificar puerto 80 ==="
sudo netstat -tulpn | grep ":80" || sudo ss -tulpn | grep ":80"

echo ""
echo "=== Verificar permisos ==="
ls -la /etc/nginx/sites-available/dashboard.checkin24hs.com
ls -la /etc/nginx/sites-enabled/dashboard.checkin24hs.com

echo ""
echo "=== Verificar configuración ==="
cat /etc/nginx/sites-available/dashboard.checkin24hs.com

