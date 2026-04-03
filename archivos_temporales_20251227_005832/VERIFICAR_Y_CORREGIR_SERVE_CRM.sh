#!/bin/bash

# Script para verificar y corregir serve-crm.js en el contenedor

SERVICE_NAME="checkin24hs_crm"

echo "=== Verificando serve-crm.js en el contenedor ==="

# Obtener contenedor
CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontró contenedor corriendo"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"

# Ver primeras líneas del archivo en el contenedor
echo ""
echo "Primeras 10 líneas de serve-crm.js en el contenedor:"
docker exec $CONTAINER_ID head -10 /app/serve-crm.js

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si falta 'const app = express();', necesitas corregir el archivo en GitHub"






