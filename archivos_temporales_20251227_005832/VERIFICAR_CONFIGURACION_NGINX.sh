#!/bin/bash
# Verificar configuración de Nginx para el dashboard

echo "=== 1. Verificar estado de Nginx ==="
systemctl status nginx --no-pager | head -10

echo ""
echo "=== 2. Buscar configuración de dashboard.checkin24hs.com ==="
find /etc/nginx -name "*dashboard*" -o -name "*checkin24hs*" 2>/dev/null

echo ""
echo "=== 3. Ver configuración de Nginx ==="
if [ -f "/etc/nginx/sites-available/dashboard.checkin24hs.com" ]; then
    echo "✅ Archivo encontrado: /etc/nginx/sites-available/dashboard.checkin24hs.com"
    cat /etc/nginx/sites-available/dashboard.checkin24hs.com
elif [ -f "/etc/nginx/conf.d/dashboard.conf" ]; then
    echo "✅ Archivo encontrado: /etc/nginx/conf.d/dashboard.conf"
    cat /etc/nginx/conf.d/dashboard.conf
else
    echo "⚠️  No se encontró configuración específica"
    echo "Buscando en todos los archivos de configuración..."
    grep -r "dashboard.checkin24hs.com" /etc/nginx/ 2>/dev/null | head -10
fi

echo ""
echo "=== 4. Verificar sintaxis de Nginx ==="
sudo nginx -t

echo ""
echo "=== 5. Ver logs de error de Nginx ==="
sudo tail -20 /var/log/nginx/error.log | grep -i "dashboard\|502" || echo "No hay errores recientes"

echo ""
echo "=== 6. Verificar que el servicio dashboard esté accesible ==="
curl -s http://localhost:3000 | head -5

