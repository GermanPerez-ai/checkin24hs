#!/bin/bash
# Verificar que el archivo realmente se actualizó

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

echo "=========================================="
echo "🔍 VERIFICACIÓN DETALLADA"
echo "=========================================="
echo ""

echo "1. Verificando archivo en /root/checkin24hs/ (bind mount)..."
if [ -f "/root/checkin24hs/cotizador-cliente.html" ]; then
    SIZE=$(wc -c < /root/checkin24hs/cotizador-cliente.html)
    echo "   Tamaño: $SIZE bytes"
    if grep -q "showPromotionValidationModal" /root/checkin24hs/cotizador-cliente.html; then
        echo "   ✅ showPromotionValidationModal encontrada"
    else
        echo "   ❌ showPromotionValidationModal NO encontrada"
    fi
    echo "   Fecha de modificación: $(ls -lh /root/checkin24hs/cotizador-cliente.html | awk '{print $6, $7, $8}')"
else
    echo "   ❌ Archivo no existe"
fi

echo ""
echo "2. Verificando archivo en contenedor..."
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    if docker exec "$CONTAINER_ID" test -f /usr/share/nginx/html/index.html 2>/dev/null; then
        CONTAINER_SIZE=$(docker exec "$CONTAINER_ID" wc -c < /usr/share/nginx/html/index.html 2>/dev/null | tr -d ' ')
        echo "   Tamaño: $CONTAINER_SIZE bytes"
        if docker exec "$CONTAINER_ID" grep -q "showPromotionValidationModal" /usr/share/nginx/html/index.html 2>/dev/null; then
            echo "   ✅ showPromotionValidationModal encontrada"
        else
            echo "   ❌ showPromotionValidationModal NO encontrada"
        fi
        echo "   Fecha: $(docker exec "$CONTAINER_ID" ls -lh /usr/share/nginx/html/index.html 2>/dev/null | awk '{print $6, $7, $8}')"
    fi
fi

echo ""
echo "3. Verificando configuración del servicio (bind mounts)..."
docker service inspect "$SERVICE_NAME" --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}' 2>/dev/null | python3 -m json.tool 2>/dev/null || docker service inspect "$SERVICE_NAME" --pretty | grep -i "mount" -A 10

echo ""
echo "4. Comparando con GitHub..."
GITHUB_SIZE=$(curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html | wc -c)
echo "   Tamaño en GitHub: $GITHUB_SIZE bytes"

echo ""
echo "5. Buscando otros lugares donde pueda estar el archivo..."
find /root -name "cotizador-cliente.html" -o -name "index.html" 2>/dev/null | grep -v "/tmp" | head -10

echo ""
echo "=========================================="
