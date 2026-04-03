#!/bin/bash
# Script para configurar nginx solo en puerto 3006 sin conflictos

echo "=========================================="
echo "CONFIGURAR NGINX SOLO EN PUERTO 3006"
echo "=========================================="
echo ""

# Verificar qué está usando los puertos 80, 443, 8080
echo "Verificando qué está usando los puertos 80, 443, 8080..."
echo "Puerto 80:"
sudo lsof -i :80 2>/dev/null || netstat -tulpn | grep :80 | head -2
echo ""
echo "Puerto 443:"
sudo lsof -i :443 2>/dev/null || netstat -tulpn | grep :443 | head -2
echo ""
echo "Puerto 8080:"
sudo lsof -i :8080 2>/dev/null || netstat -tulpn | grep :8080 | head -2
echo ""

# Deshabilitar todas las configuraciones de nginx que usan puertos conflictivos
echo "Deshabilitando configuraciones de nginx que causan conflictos..."
cd /etc/nginx/sites-enabled

# Deshabilitar configuraciones que escuchan en 80, 443, 8080
for file in *; do
    if [ -f "$file" ] && [ "$file" != "easypanel-3006" ]; then
        if grep -q "listen.*80\|listen.*443\|listen.*8080" "/etc/nginx/sites-available/$file" 2>/dev/null; then
            echo "Deshabilitando: $file"
            sudo rm -f "$file"
        fi
    fi
done

echo "✅ Configuraciones conflictivas deshabilitadas"
echo ""

# Verificar que solo quede la configuración de 3006
echo "Configuraciones activas en nginx:"
ls -la /etc/nginx/sites-enabled/
echo ""

# Verificar que la configuración de 3006 existe y está correcta
if [ ! -f "/etc/nginx/sites-available/easypanel-3006" ]; then
    echo "ERROR: No se encontró la configuración de easypanel-3006"
    echo "Creando configuración..."
    sudo tee /etc/nginx/sites-available/easypanel-3006 > /dev/null <<EOF
server {
    listen 3006;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    sudo ln -s /etc/nginx/sites-available/easypanel-3006 /etc/nginx/sites-enabled/
    echo "✅ Configuración creada"
fi
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
    echo "Verificando estado de nginx..."
    sudo systemctl status nginx --no-pager | head -10
fi
echo ""

echo "=========================================="
echo "CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Ahora puedes acceder a EasyPanel en:"
echo "  http://72.61.58.240:3006"
echo ""
echo "Nota: Los puertos 80, 443 y 8080 siguen siendo usados por otros servicios"
echo "      (probablemente Traefik o Docker). Esto es normal."
echo ""
