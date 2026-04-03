#!/bin/bash
# Script para recrear EasyPanel en puerto 8090

echo "=========================================="
echo "RECREAR EASYPANEL EN PUERTO 8090"
echo "=========================================="
echo ""

EASYPANEL_CONTAINER="1beb93cc85e7"

# 1. Detener y eliminar el contenedor actual
echo "1. Deteniendo y eliminando contenedor actual..."
docker stop $EASYPANEL_CONTAINER 2>/dev/null
docker rm $EASYPANEL_CONTAINER 2>/dev/null
echo "✅ Contenedor eliminado"
echo ""

# 2. Verificar que la red easypanel existe
echo "2. Verificando red easypanel..."
if ! docker network ls | grep -q easypanel; then
    echo "Creando red easypanel..."
    docker network create easypanel
    echo "✅ Red creada"
else
    echo "✅ Red easypanel ya existe"
fi
echo ""

# 3. Recrear EasyPanel mapeando puerto 8090 del host al 3000 del contenedor
echo "3. Creando nuevo contenedor de EasyPanel en puerto 8090..."
docker run -d \
    --name easypanel \
    --restart unless-stopped \
    --network easypanel \
    -p 8090:3000 \
    -v /etc/easypanel:/etc/easypanel \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    easypanel/easypanel:latest

if [ $? -eq 0 ]; then
    echo "✅ Contenedor creado"
else
    echo "❌ Error creando contenedor"
    exit 1
fi
echo ""

# 4. Esperar a que inicie
echo "4. Esperando 15 segundos para que EasyPanel inicie..."
sleep 15
echo ""

# 5. Verificar que esté corriendo
echo "5. Verificando estado del contenedor..."
docker ps | grep easypanel
echo ""

# 6. Verificar que el puerto 8090 esté escuchando
echo "6. Verificando que el puerto 8090 esté escuchando..."
if netstat -tuln | grep -q ":8090 "; then
    echo "✅ Puerto 8090 está escuchando"
    netstat -tuln | grep 8090
else
    echo "⚠️ Puerto 8090 no está escuchando aún (puede tardar unos segundos más)"
fi
echo ""

# 7. Verificar que EasyPanel responda
echo "7. Verificando que EasyPanel responda..."
sleep 5
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8090 | grep -q "200\|301\|302"; then
    echo "✅ EasyPanel está respondiendo en puerto 8090"
else
    echo "⚠️ EasyPanel aún no responde (puede tardar más tiempo)"
    echo "   Revisa los logs: docker logs easypanel --tail 20"
fi
echo ""

echo "=========================================="
echo "EASYPANEL RECREADO"
echo "=========================================="
echo ""
echo "Ahora actualiza la configuración de nginx:"
echo "  sudo nano /etc/nginx/sites-available/easypanel-3006"
echo "  Cambia: proxy_pass http://127.0.0.1:3000;"
echo "  Por:    proxy_pass http://127.0.0.1:8090;"
echo ""
echo "Luego:"
echo "  sudo nginx -t"
echo "  sudo systemctl reload nginx"
echo ""
