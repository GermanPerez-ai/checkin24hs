#!/bin/bash
# Script para actualizar nginx para que apunte a EasyPanel en puerto 8090

echo "=========================================="
echo "ACTUALIZAR NGINX PARA EASYPANEL"
echo "=========================================="
echo ""

# Ver configuración actual
echo "1. Configuración actual:"
cat /etc/nginx/sites-available/easypanel-3006
echo ""

# Actualizar proxy_pass
echo "2. Actualizando proxy_pass a puerto 8090..."
sudo sed -i 's|proxy_pass http://127.0.0.1:3000;|proxy_pass http://127.0.0.1:8090;|g' /etc/nginx/sites-available/easypanel-3006

if [ $? -eq 0 ]; then
    echo "✅ Configuración actualizada"
else
    echo "❌ Error actualizando configuración"
    exit 1
fi
echo ""

# Ver configuración actualizada
echo "3. Configuración actualizada:"
cat /etc/nginx/sites-available/easypanel-3006
echo ""

# Verificar configuración
echo "4. Verificando configuración de nginx..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Error en la configuración de nginx"
    exit 1
fi

echo "✅ Configuración válida"
echo ""

# Recargar nginx
echo "5. Recargando nginx..."
sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ nginx recargado"
else
    echo "❌ Error recargando nginx"
    exit 1
fi
echo ""

# Verificar que funcione
echo "6. Verificando que EasyPanel responda en puerto 3006..."
sleep 2
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3006)

if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "301" ] || [ "$RESPONSE" = "302" ]; then
    echo "✅ EasyPanel está respondiendo (HTTP $RESPONSE)"
    
    # Verificar que no sea el dashboard (el dashboard tiene X-Powered-By: Express)
    HEADERS=$(curl -s -I http://127.0.0.1:3006)
    if echo "$HEADERS" | grep -q "X-Powered-By: Express"; then
        echo "⚠️ Advertencia: Parece que aún está mostrando el dashboard"
        echo "   Verifica que EasyPanel esté corriendo en puerto 8090:"
        echo "   docker ps | grep easypanel"
        echo "   curl -I http://127.0.0.1:8090"
    else
        echo "✅ Parece que está mostrando EasyPanel correctamente"
    fi
else
    echo "⚠️ EasyPanel no responde (HTTP $RESPONSE)"
fi
echo ""

echo "=========================================="
echo "ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Prueba acceder a: http://72.61.58.240:3006"
echo ""
