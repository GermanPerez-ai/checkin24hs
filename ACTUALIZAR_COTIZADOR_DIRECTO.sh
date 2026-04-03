#!/bin/bash
# Script simplificado para actualizar cotizador directamente

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
CONTAINER_PATH="/usr/share/nginx/html/"

echo "Servicio: $SERVICE_NAME"
echo "Contenedor: $CONTAINER_ID"
echo ""

# Crear directorio temporal
TEMP_DIR="/tmp/cotizador_update_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "Descargando archivos desde GitHub..."
curl -L -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
curl -L -o supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
curl -L -o supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js

echo ""
echo "Verificando descarga..."
FILE_SIZE=$(wc -c < cotizador-cliente.html)
echo "Tamaño descargado: $FILE_SIZE bytes"
if [ "$FILE_SIZE" -lt 80000 ]; then
    echo "⚠️  ADVERTENCIA: El archivo parece incompleto (debería ser ~81KB)"
fi

# Verificar que tiene las funciones necesarias
if grep -q "showPromotionValidationModal" cotizador-cliente.html; then
    echo "✅ Función showPromotionValidationModal encontrada en archivo descargado"
else
    echo "❌ ERROR: showPromotionValidationModal NO encontrada en archivo descargado"
    echo "   El archivo en GitHub puede no estar actualizado"
fi

echo ""
echo "Copiando archivos al contenedor..."
docker cp cotizador-cliente.html "$CONTAINER_ID:${CONTAINER_PATH}cotizador-cliente.html"
docker cp cotizador-cliente.html "$CONTAINER_ID:${CONTAINER_PATH}index.html"
docker cp supabase-config.js "$CONTAINER_ID:${CONTAINER_PATH}supabase-config.js"
docker cp supabase-client.js "$CONTAINER_ID:${CONTAINER_PATH}supabase-client.js"

echo ""
echo "Reiniciando servicio..."
docker service update --force "$SERVICE_NAME"

cd /
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Actualización completada"
