#!/bin/bash
# Diagnosticar error 502 del dashboard desde SSH

echo "=== DIAGNÓSTICO DEL DASHBOARD ==="
echo ""

echo "1. Verificar servicios PM2 relacionados con dashboard:"
pm2 list | grep -i "dashboard\|crm\|server"

echo ""
echo "2. Verificar procesos Node.js corriendo:"
ps aux | grep -i "node.*server\|node.*dashboard" | grep -v grep

echo ""
echo "3. Verificar puerto 3000 (puerto común del dashboard):"
netstat -tulpn | grep ":3000" || ss -tulpn | grep ":3000"

echo ""
echo "4. Verificar si existe server.js:"
if [ -f "server.js" ]; then
    echo "✅ server.js existe"
    head -20 server.js | grep -E "PORT|listen|3000"
else
    echo "❌ server.js no encontrado en el directorio actual"
    find ~ -name "server.js" -type f 2>/dev/null | head -3
fi

echo ""
echo "5. Verificar si existe dashboard.html:"
find ~/checkin24hs -name "dashboard.html" -type f 2>/dev/null | head -3

echo ""
echo "6. Verificar configuración de Nginx:"
if [ -f "/etc/nginx/sites-available/dashboard.checkin24hs.com" ]; then
    echo "✅ Archivo de configuración encontrado"
    grep -E "server_name|proxy_pass|root" /etc/nginx/sites-available/dashboard.checkin24hs.com | head -10
elif [ -f "/etc/nginx/conf.d/dashboard.conf" ]; then
    echo "✅ Archivo de configuración encontrado"
    grep -E "server_name|proxy_pass|root" /etc/nginx/conf.d/dashboard.conf | head -10
else
    echo "⚠️  No se encontró configuración específica de Nginx para dashboard"
    echo "Buscando en otros lugares..."
    find /etc/nginx -name "*dashboard*" -o -name "*checkin24hs*" 2>/dev/null
fi

echo ""
echo "7. Verificar estado de Nginx:"
systemctl status nginx --no-pager | head -10

echo ""
echo "8. Ver logs de error de Nginx:"
tail -20 /var/log/nginx/error.log 2>/dev/null | grep -i "dashboard\|502" || echo "No hay errores recientes en logs"

