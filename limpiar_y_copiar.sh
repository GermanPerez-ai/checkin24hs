#!/bin/bash

cd /root/checkin24hs

echo "🔍 Verificando archivo local..."
LOCAL_HTML_COUNT=$(grep -c "<html" deploy/dashboard.html)
LOCAL_HTML_CLOSE_COUNT=$(grep -c "</html>" deploy/dashboard.html)
echo "Archivo local: <html>=$LOCAL_HTML_COUNT, </html>=$LOCAL_HTML_CLOSE_COUNT"

if [ "$LOCAL_HTML_COUNT" != "1" ] || [ "$LOCAL_HTML_CLOSE_COUNT" != "1" ]; then
    echo "⚠️ El archivo local está corrupto. Buscando líneas problemáticas..."
    grep -n "<html" deploy/dashboard.html | head -5
    grep -n "</html>" deploy/dashboard.html | head -5
    exit 1
fi

echo "✅ Archivo local está correcto"
echo ""

# Obtener contenedor
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedores activos"
    exit 1
fi

DASHBOARD_PATH="/app/dashboard.html"
docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"

echo "📦 Contenedor: $CONTAINER_ID"
echo "📁 Ruta: $DASHBOARD_PATH"
echo ""

# Eliminar BOM si existe y copiar
echo "🧹 Limpiando BOM y copiando archivo..."
# Remover BOM UTF-8 si existe
sed '1s/^\xEF\xBB\xBF//' deploy/dashboard.html > /tmp/dashboard_clean.html

# Verificar archivo limpio
CLEAN_HTML_COUNT=$(grep -c "<html" /tmp/dashboard_clean.html)
CLEAN_HTML_CLOSE_COUNT=$(grep -c "</html>" /tmp/dashboard_clean.html)
echo "Archivo limpio: <html>=$CLEAN_HTML_COUNT, </html>=$CLEAN_HTML_CLOSE_COUNT"

if [ "$CLEAN_HTML_COUNT" != "1" ] || [ "$CLEAN_HTML_CLOSE_COUNT" != "1" ]; then
    echo "⚠️ El archivo limpio sigue corrupto"
    exit 1
fi

# Copiar archivo limpio
docker cp /tmp/dashboard_clean.html "${CONTAINER_ID}:${DASHBOARD_PATH}"

# Verificar en contenedor
echo "✅ Verificando en contenedor:"
CONTAINER_HTML_COUNT=$(docker exec $CONTAINER_ID grep -c "<html" "$DASHBOARD_PATH")
CONTAINER_HTML_CLOSE_COUNT=$(docker exec $CONTAINER_ID grep -c "</html>" "$DASHBOARD_PATH")
echo "  <html>: $CONTAINER_HTML_COUNT"
echo "  </html>: $CONTAINER_HTML_CLOSE_COUNT"

if [ "$CONTAINER_HTML_COUNT" = "1" ] && [ "$CONTAINER_HTML_CLOSE_COUNT" = "1" ]; then
    echo "✅ Archivo copiado correctamente"
    echo "🔄 Reiniciando contenedor..."
    docker restart $CONTAINER_ID
    sleep 5
    echo "✅ Proceso completado"
else
    echo "❌ El archivo en el contenedor sigue corrupto"
    echo "🔍 Verificando línea 21403:"
    docker exec $CONTAINER_ID sed -n '21403p' "$DASHBOARD_PATH" | head -c 100
    echo ""
fi

# Limpiar archivo temporal
rm -f /tmp/dashboard_clean.html


