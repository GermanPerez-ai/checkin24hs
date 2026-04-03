#!/bin/bash
# Aplicar bind mount directamente al servicio usando Docker

SERVICE_NAME="checkin24hs_cotizador"

echo "=========================================="
echo "🔧 APLICAR BIND MOUNT AL SERVICIO"
echo "=========================================="
echo ""

echo "1. Verificando configuración actual..."
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>/dev/null

echo ""
echo "2. Aplicando bind mount directamente..."
echo ""

# Aplicar bind mount usando docker service update
docker service update \
  --mount-add type=bind,source=/root/checkin24hs,target=/usr/share/nginx/html \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Bind mount aplicado"
else
    echo "❌ Error al aplicar bind mount"
    echo ""
    echo "Intentando método alternativo..."
    
    # Si falla, intentar agregar el mount de otra forma
    docker service update \
      --mount-add "type=bind,source=/root/checkin24hs,destination=/usr/share/nginx/html" \
      "$SERVICE_NAME"
fi

echo ""
echo "3. Esperando 30 segundos para que se aplique..."
sleep 30

echo ""
echo "4. Verificando nuevo contenedor..."
NEW_CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "   Nuevo contenedor: $NEW_CONTAINER_ID"
    echo ""
    
    echo "   Verificando mounts:"
    docker exec "$NEW_CONTAINER_ID" mount | grep -E "nginx|html" || echo "   (no encontrado)"
    echo ""
    
    echo "   Verificando inode:"
    HOST_INODE=$(stat -c %i /root/checkin24hs/index.html 2>/dev/null)
    CONTAINER_INODE=$(docker exec "$NEW_CONTAINER_ID" stat -c %i /usr/share/nginx/html/index.html 2>/dev/null)
    echo "   Inode host: $HOST_INODE"
    echo "   Inode contenedor: $CONTAINER_INODE"
    
    if [ "$HOST_INODE" = "$CONTAINER_INODE" ] && [ ! -z "$HOST_INODE" ]; then
        echo "   ✅ Bind mount funcionando"
        
        if docker exec "$NEW_CONTAINER_ID" grep -q "showPromotionValidationModal" /usr/share/nginx/html/index.html 2>/dev/null; then
            echo "   ✅ showPromotionValidationModal encontrada"
        else
            echo "   ❌ showPromotionValidationModal NO encontrada"
        fi
    else
        echo "   ❌ Bind mount aún NO funciona"
        echo ""
        echo "   Puede ser necesario recrear el servicio desde EasyPanel"
    fi
fi

echo ""
echo "=========================================="
