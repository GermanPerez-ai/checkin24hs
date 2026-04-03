#!/bin/bash
# Verificar si el contenedor mantiene los cambios después del reinicio

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

echo "Verificando contenedor después del reinicio..."
echo ""
echo "Contenedor actual: $CONTAINER_ID"
echo ""

if [ ! -z "$CONTAINER_ID" ]; then
    echo "Verificando archivo en contenedor..."
    if docker exec "$CONTAINER_ID" test -f /usr/share/nginx/html/index.html 2>/dev/null; then
        SIZE=$(docker exec "$CONTAINER_ID" stat -c %s /usr/share/nginx/html/index.html 2>/dev/null)
        echo "Tamaño: $SIZE bytes"
        
        if docker exec "$CONTAINER_ID" grep -q "showPromotionValidationModal" /usr/share/nginx/html/index.html 2>/dev/null; then
            echo "✅ showPromotionValidationModal encontrada"
        else
            echo "❌ showPromotionValidationModal NO encontrada"
            echo ""
            echo "El contenedor se recreó y perdió los cambios."
            echo "Necesitas configurar un bind mount o actualizar la imagen Docker."
        fi
    fi
fi

echo ""
echo "Historial del servicio (últimos 3):"
docker service ps "$SERVICE_NAME" --no-trunc | head -4
