#!/bin/bash

# Script para verificar y corregir el archivo en el contenedor

SERVICE_NAME="checkin24hs_crm"

echo "=== Verificando archivo en contenedor ==="

CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontró contenedor corriendo"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""
echo "Primeras 10 líneas de serve-crm.js:"
docker exec $CONTAINER_ID head -10 /app/serve-crm.js

echo ""
echo "=== Verificando si falta 'const app = express()' ==="
if docker exec $CONTAINER_ID grep -q "const app = express()" /app/serve-crm.js; then
    echo "✅ La línea 'const app = express()' está presente"
else
    echo "❌ ERROR: La línea 'const app = express()' NO está presente"
    echo ""
    echo "Necesitas reconstruir el servicio desde EasyPanel con el archivo correcto de GitHub"
fi






