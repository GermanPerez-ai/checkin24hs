#!/bin/bash

# Script para verificar el contenido real del archivo en el contenedor

SERVICE_NAME="checkin24hs_crm"

echo "=== Verificando serve-crm.js en contenedores ==="

# Obtener todos los contenedores del servicio
CONTAINERS=$(docker ps -a --filter "name=$SERVICE_NAME" --format "{{.ID}}")

for CONTAINER_ID in $CONTAINERS; do
    echo ""
    echo "Contenedor: $CONTAINER_ID"
    echo "Primeras 10 líneas de serve-crm.js:"
    docker exec $CONTAINER_ID head -10 /app/serve-crm.js 2>&1 | head -10
    echo "---"
done

echo ""
echo "=== Verificación completada ==="






