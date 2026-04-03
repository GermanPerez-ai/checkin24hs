#!/bin/bash

echo "=========================================="
echo "🔧 SOLUCIONANDO PROBLEMA DE NGINX"
echo "=========================================="
echo ""

# 1. Verificar estado de nginx
echo "1️⃣ Estado actual de nginx:"
echo "=========================================="
systemctl status nginx --no-pager -l | head -15
echo ""

# 2. Verificar configuración de nginx
echo "2️⃣ Verificando configuración de nginx:"
echo "=========================================="
if [ -d "/etc/nginx/sites-enabled" ]; then
    echo "Archivos de configuración encontrados:"
    ls -la /etc/nginx/sites-enabled/
    echo ""
    echo "Buscando configuración de api1.checkin24hs.com:"
    grep -r "api1.checkin24hs.com" /etc/nginx/sites-enabled/ 2>/dev/null || echo "No se encontró configuración"
else
    echo "❌ Directorio /etc/nginx/sites-enabled no existe"
fi
echo ""

# 3. Verificar sintaxis de configuración
echo "3️⃣ Verificando sintaxis de configuración:"
echo "=========================================="
nginx -t 2>&1
echo ""

# 4. Ver logs de nginx para ver el error
echo "4️⃣ Últimos errores de nginx:"
echo "=========================================="
journalctl -u nginx --no-pager -n 20 2>&1 | tail -20
echo ""

# 5. Intentar iniciar nginx
echo "5️⃣ Intentando iniciar nginx:"
echo "=========================================="
systemctl start nginx 2>&1
sleep 2
systemctl status nginx --no-pager -l | head -10
echo ""

echo "=========================================="
echo "📋 PRÓXIMOS PASOS:"
echo "=========================================="
echo ""
echo "Si nginx tiene errores de configuración:"
echo "  1. Revisa los errores mostrados arriba"
echo "  2. Corrige la configuración en /etc/nginx/sites-enabled/"
echo "  3. Ejecuta: nginx -t (para verificar sintaxis)"
echo "  4. Ejecuta: systemctl restart nginx"
echo ""
echo "Si nginx inicia correctamente:"
echo "  1. Verifica que el proxy apunte al puerto correcto (3001)"
echo "  2. Prueba: curl -I https://api1.checkin24hs.com/api/status?card=1"
echo ""



