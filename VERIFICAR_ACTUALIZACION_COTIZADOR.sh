#!/bin/bash
# Script para verificar que los archivos se actualizaron correctamente

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
CONTAINER_PATH="/usr/share/nginx/html/"

echo "=========================================="
echo "🔍 VERIFICAR ACTUALIZACIÓN DEL COTIZADOR"
echo "=========================================="
echo ""
echo "Servicio: $SERVICE_NAME"
echo "Contenedor: $CONTAINER_ID"
echo ""

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "1️⃣ Verificando archivos en el contenedor..."
echo ""
docker exec "$CONTAINER_ID" ls -lh "$CONTAINER_PATH" | grep -E "cotizador|index.html|supabase"
echo ""

echo "2️⃣ Verificando contenido de index.html (primeras líneas)..."
echo ""
docker exec "$CONTAINER_ID" head -20 "$CONTAINER_PATH/index.html" | head -5
echo ""

echo "3️⃣ Buscando validación de promociones en index.html..."
echo ""
if docker exec "$CONTAINER_ID" grep -q "validatePromotionRange" "$CONTAINER_PATH/index.html" 2>/dev/null; then
    echo "   ✅ Función validatePromotionRange encontrada"
else
    echo "   ❌ Función validatePromotionRange NO encontrada"
fi

if docker exec "$CONTAINER_ID" grep -q "showPromotionValidationModal" "$CONTAINER_PATH/index.html" 2>/dev/null; then
    echo "   ✅ Función showPromotionValidationModal encontrada"
else
    echo "   ❌ Función showPromotionValidationModal NO encontrada"
fi
echo ""

echo "4️⃣ Comparando con GitHub (verificando fecha de última actualización)..."
echo ""
# Descargar una pequeña porción para verificar
curl -s -I https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html | grep -i "last-modified" || echo "   (no se pudo obtener fecha)"
echo ""

echo "5️⃣ Verificando tamaño de archivos..."
echo ""
LOCAL_SIZE=$(curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html | wc -c)
CONTAINER_SIZE=$(docker exec "$CONTAINER_ID" wc -c < "$CONTAINER_PATH/index.html" 2>/dev/null)
echo "   Tamaño en GitHub: $LOCAL_SIZE bytes"
echo "   Tamaño en contenedor: $CONTAINER_SIZE bytes"
if [ "$LOCAL_SIZE" -eq "$CONTAINER_SIZE" ]; then
    echo "   ✅ Los tamaños coinciden"
else
    echo "   ⚠️  Los tamaños NO coinciden - puede haber un problema"
fi
echo ""

echo "6️⃣ Verificando que el servicio está corriendo..."
echo ""
docker service ps "$SERVICE_NAME" --no-trunc | head -3
echo ""

echo "=========================================="
echo "📋 RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si los archivos no se actualizaron:"
echo "   1. Ejecuta de nuevo: ./ACTUALIZAR_COTIZADOR_DIRECTO.sh"
echo "   2. O verifica manualmente:"
echo "      docker exec $CONTAINER_ID cat $CONTAINER_PATH/index.html | head -50"
echo ""
echo "Si los archivos están actualizados pero no se ven cambios:"
echo "   1. Limpia la caché del navegador (Ctrl+Shift+R)"
echo "   2. Abre en modo incógnito"
echo "   3. Verifica que no haya un CDN o proxy cacheando"
echo ""
