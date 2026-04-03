#!/bin/bash
# Verificar si el bind mount está funcionando correctamente

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

echo "=========================================="
echo "🔍 VERIFICAR BIND MOUNT"
echo "=========================================="
echo ""

echo "1. Verificando bind mount en el contenedor..."
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    echo ""
    echo "   Mounts en el contenedor:"
    docker exec "$CONTAINER_ID" mount | grep "/usr/share/nginx/html" || echo "   ⚠️  No se encontró mount en /usr/share/nginx/html"
    echo ""
    
    echo "   Verificando si /usr/share/nginx/html es un directorio montado:"
    docker exec "$CONTAINER_ID" df -h /usr/share/nginx/html 2>/dev/null || echo "   (no se pudo verificar)"
    echo ""
    
    echo "   Archivos en /usr/share/nginx/html/:"
    docker exec "$CONTAINER_ID" ls -lah /usr/share/nginx/html/ | head -10
    echo ""
    
    echo "   Verificando inode de index.html (para ver si es el mismo archivo):"
    HOST_INODE=$(stat -c %i /root/checkin24hs/index.html 2>/dev/null)
    CONTAINER_INODE=$(docker exec "$CONTAINER_ID" stat -c %i /usr/share/nginx/html/index.html 2>/dev/null)
    echo "   Inode en host: $HOST_INODE"
    echo "   Inode en contenedor: $CONTAINER_INODE"
    if [ "$HOST_INODE" = "$CONTAINER_INODE" ]; then
        echo "   ✅ Los inodes coinciden - el bind mount está funcionando"
    else
        echo "   ❌ Los inodes NO coinciden - el bind mount NO está funcionando"
    fi
fi

echo ""
echo "2. Verificando configuración del servicio..."
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>/dev/null

echo ""
echo "3. Si el bind mount no funciona, puede ser que:"
echo "   - El servicio necesite recrearse completamente"
echo "   - Haya un problema con la configuración en EasyPanel"
echo "   - Los archivos en la imagen Docker estén sobrescribiendo el bind mount"
echo ""
