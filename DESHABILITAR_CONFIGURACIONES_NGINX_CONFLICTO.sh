#!/bin/bash
# Script para deshabilitar configuraciones de nginx que usan puertos 80 y 443

echo "=========================================="
echo "DESHABILITAR CONFIGURACIONES CON CONFLICTO"
echo "=========================================="
echo ""

cd /etc/nginx/sites-enabled

# Deshabilitar configuraciones que usan puertos 80 y 443
echo "Deshabilitando configuraciones que usan puertos 80 y 443..."

# Deshabilitar dashboard.checkin24hs.com si escucha en 80 o 443
if [ -L "dashboard.checkin24hs.com" ]; then
    if grep -q "listen.*80\|listen.*443" /etc/nginx/sites-available/dashboard.checkin24hs.com 2>/dev/null; then
        echo "Deshabilitando: dashboard.checkin24hs.com"
        sudo rm -f dashboard.checkin24hs.com
    fi
fi

# Deshabilitar webmail.checkin24hs.com si escucha en 80 o 443
if [ -L "webmail.checkin24hs.com" ]; then
    if grep -q "listen.*80\|listen.*443" /etc/nginx/sites-available/webmail.checkin24hs.com 2>/dev/null; then
        echo "Deshabilitando: webmail.checkin24hs.com"
        sudo rm -f webmail.checkin24hs.com
    fi
fi

echo "✅ Configuraciones conflictivas deshabilitadas"
echo ""

# Verificar configuraciones activas
echo "Configuraciones activas:"
ls -la
echo ""

# Verificar configuración de nginx
echo "Verificando configuración de nginx..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "ERROR: La configuración de nginx tiene errores"
    exit 1
fi

echo "✅ Configuración válida"
echo ""

# Iniciar nginx
echo "Iniciando nginx..."
sudo systemctl start nginx

if [ $? -eq 0 ]; then
    echo "✅ nginx iniciado correctamente"
else
    echo "ERROR: No se pudo iniciar nginx"
    echo ""
    echo "Revisando logs..."
    sudo journalctl -u nginx --no-pager -n 10
    exit 1
fi
echo ""

# Verificar que nginx esté corriendo
if sudo systemctl is-active --quiet nginx; then
    echo "✅ nginx está corriendo"
else
    echo "ERROR: nginx no está corriendo"
    exit 1
fi
echo ""

# Verificar que el puerto 3006 esté escuchando
echo "Verificando que el puerto 3006 esté escuchando..."
sleep 2
if netstat -tuln | grep -q ":3006 "; then
    echo "✅ Puerto 3006 está escuchando"
    netstat -tuln | grep 3006
else
    echo "⚠️ El puerto 3006 no está escuchando aún"
fi
echo ""

echo "=========================================="
echo "CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Ahora puedes acceder a EasyPanel en:"
echo "  http://72.61.58.240:3006"
echo ""
echo "Nota: Las configuraciones de dashboard y webmail fueron deshabilitadas"
echo "      temporalmente. Puedes reactivarlas después si es necesario."
echo ""
