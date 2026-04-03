#!/bin/bash

cd /root/checkin24hs

echo "🔍 Verificando archivo en el servidor..."

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor dashboard"
    exit 1
fi

DASHBOARD_PATH="/app/dashboard.html"
docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"

echo "📁 Ruta en contenedor: $DASHBOARD_PATH"
echo ""

# Verificar tamaño del archivo
echo "📊 Tamaño del archivo:"
docker exec $CONTAINER_ID wc -l "$DASHBOARD_PATH"
echo ""

# Verificar línea 21403
echo "🔍 Verificando línea 21403:"
docker exec $CONTAINER_ID sed -n '21403p' "$DASHBOARD_PATH" | head -c 100
echo ""
echo ""

# Verificar si hay contenido duplicado (buscar múltiples declaraciones de SUPABASE_CONFIG)
echo "🔍 Buscando declaraciones de SUPABASE_CONFIG:"
docker exec $CONTAINER_ID grep -c "const SUPABASE_CONFIG\|let SUPABASE_CONFIG\|var SUPABASE_CONFIG" "$DASHBOARD_PATH" || echo "0"
echo ""

# Verificar si hay múltiples etiquetas <html>
echo "🔍 Buscando etiquetas <html>:"
docker exec $CONTAINER_ID grep -c "<html" "$DASHBOARD_PATH"
echo ""

# Verificar si hay múltiples etiquetas </html>
echo "🔍 Buscando etiquetas </html>:"
docker exec $CONTAINER_ID grep -c "</html>" "$DASHBOARD_PATH"
echo ""

# Verificar si hay múltiples etiquetas <body>
echo "🔍 Buscando etiquetas <body>:"
docker exec $CONTAINER_ID grep -c "<body" "$DASHBOARD_PATH"
echo ""

# Comparar con archivo local
echo "📊 Comparando con archivo local:"
LOCAL_LINES=$(wc -l < deploy/dashboard.html)
CONTAINER_LINES=$(docker exec $CONTAINER_ID wc -l < "$DASHBOARD_PATH")
echo "  Local: $LOCAL_LINES líneas"
echo "  Contenedor: $CONTAINER_LINES líneas"
if [ "$LOCAL_LINES" != "$CONTAINER_LINES" ]; then
    echo "  ⚠️ Los archivos tienen diferente número de líneas"
else
    echo "  ✅ Los archivos tienen el mismo número de líneas"
fi
