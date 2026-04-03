#!/bin/bash
# Script para configurar EasyPanel en el puerto 3006 usando nginx como proxy

echo "=========================================="
echo "CONFIGURAR EASYPANEL EN PUERTO 3006"
echo "=========================================="
echo ""

# Verificar si nginx está instalado
if ! command -v nginx &> /dev/null; then
    echo "Instalando nginx..."
    sudo apt update
    sudo apt install -y nginx
    if [ $? -ne 0 ]; then
        echo "ERROR: No se pudo instalar nginx"
        exit 1
    fi
    echo "✅ nginx instalado"
else
    echo "✅ nginx ya está instalado"
fi
echo ""

# Crear configuración de nginx para EasyPanel en puerto 3006
echo "Creando configuración de nginx..."
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
        
        # Timeouts para evitar cortes
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

if [ $? -eq 0 ]; then
    echo "✅ Configuración creada en /etc/nginx/sites-available/easypanel-3006"
else
    echo "ERROR: No se pudo crear la configuración"
    exit 1
fi
echo ""

# Activar el sitio
echo "Activando sitio..."
if [ -L /etc/nginx/sites-enabled/easypanel-3006 ]; then
    echo "⚠️ El sitio ya estaba activado, eliminando enlace anterior..."
    sudo rm /etc/nginx/sites-enabled/easypanel-3006
fi

sudo ln -s /etc/nginx/sites-available/easypanel-3006 /etc/nginx/sites-enabled/

if [ $? -eq 0 ]; then
    echo "✅ Sitio activado"
else
    echo "ERROR: No se pudo activar el sitio"
    exit 1
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

# Recargar nginx
echo "Recargando nginx..."
sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ nginx recargado"
else
    echo "ERROR: No se pudo recargar nginx"
    exit 1
fi
echo ""

# Verificar que el puerto 3006 esté escuchando
echo "Verificando que el puerto 3006 esté escuchando..."
sleep 2
if netstat -tuln | grep -q ":3006 "; then
    echo "✅ Puerto 3006 está escuchando"
else
    echo "⚠️ Advertencia: El puerto 3006 no aparece como escuchando (puede tardar unos segundos)"
fi
echo ""

# Verificar que EasyPanel esté corriendo en 3000
echo "Verificando que EasyPanel esté corriendo en puerto 3000..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 | grep -q "200\|301\|302"; then
    echo "✅ EasyPanel está respondiendo en puerto 3000"
else
    echo "⚠️ Advertencia: EasyPanel no responde en puerto 3000"
    echo "   Verifica que EasyPanel esté corriendo:"
    echo "   docker ps | grep easypanel"
fi
echo ""

echo "=========================================="
echo "CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Ahora puedes acceder a EasyPanel en:"
echo "  http://72.61.58.240:3006"
echo ""
echo "El dashboard sigue funcionando en:"
echo "  http://72.61.58.240:3000"
echo "  (o https://dashboard.checkin24hs.com/)"
echo ""
