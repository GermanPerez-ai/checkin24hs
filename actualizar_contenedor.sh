#!/bin/bash

cd /root/checkin24hs

echo "📤 Actualizando contenedor dashboard..."

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor dashboard"
    exit 1
fi

DASHBOARD_PATH="/app/dashboard.html"
docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"

echo "📦 Contenedor: $CONTAINER_ID"
echo "📁 Ruta: $DASHBOARD_PATH"

echo "📤 Copiando archivo..."
docker cp deploy/dashboard.html "${CONTAINER_ID}:${DASHBOARD_PATH}"

echo "🔄 Reiniciando contenedor..."
docker restart $CONTAINER_ID
sleep 5

echo ""
echo "✅ Actualización completada"
echo ""
echo "🔍 Verificando logs de depuración en el archivo..."
docker exec $CONTAINER_ID grep -c "🔍 DEBUG: Buscando elemento con ID:" "$DASHBOARD_PATH" && echo "✅ Logs de depuración presentes" || echo "❌ Logs de depuración NO encontrados"


