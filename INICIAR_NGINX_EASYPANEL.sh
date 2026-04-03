#!/bin/bash
# Script para iniciar nginx y verificar configuración de EasyPanel

echo "=========================================="
echo "INICIAR NGINX Y VERIFICAR EASYPANEL"
echo "=========================================="
echo ""

# Verificar estado de nginx
echo "Verificando estado de nginx..."
sudo systemctl status nginx --no-pager | head -5
echo ""

# Iniciar nginx
echo "Iniciando nginx..."
sudo systemctl start nginx

if [ $? -eq 0 ]; then
    echo "✅ nginx iniciado"
else
    echo "ERROR: No se pudo iniciar nginx"
    echo ""
    echo "Verificando logs de error..."
    sudo journalctl -u nginx --no-pager -n 20
    exit 1
fi
echo ""

# Habilitar nginx para que inicie automáticamente
echo "Habilitando nginx para inicio automático..."
sudo systemctl enable nginx
echo "✅ nginx habilitado para inicio automático"
echo ""

# Verificar que nginx esté corriendo
echo "Verificando que nginx esté corriendo..."
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
    echo "Verificando configuración..."
    sudo nginx -t
    echo ""
    echo "Revisando si el archivo de configuración existe..."
    ls -la /etc/nginx/sites-available/easypanel-3006
    ls -la /etc/nginx/sites-enabled/easypanel-3006
fi
echo ""

# Verificar que EasyPanel esté corriendo en 3000
echo "Verificando que EasyPanel esté corriendo en puerto 3000..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 | grep -q "200\|301\|302"; then
    echo "✅ EasyPanel está respondiendo en puerto 3000"
else
    echo "⚠️ EasyPanel no responde en puerto 3000"
    echo "Verificando contenedores de EasyPanel..."
    docker ps | grep easypanel
fi
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Prueba acceder a EasyPanel en:"
echo "  http://72.61.58.240:3006"
echo ""
