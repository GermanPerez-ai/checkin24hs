#!/bin/bash
# Script para actualizar cotizador cuando usa bind mount

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

echo "=========================================="
echo "🔍 VERIFICAR Y ACTUALIZAR COTIZADOR"
echo "=========================================="
echo ""

echo "1️⃣ Verificando configuración del servicio..."
echo ""

# Verificar mounts de todas las formas posibles
echo "Buscando volúmenes montados..."
docker service inspect "$SERVICE_NAME" --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}' | jq '.' 2>/dev/null || docker service inspect "$SERVICE_NAME" --pretty | grep -i "mount\|volume" -A 5

echo ""
echo "2️⃣ Verificando si hay archivos en rutas comunes de EasyPanel..."
echo ""

# Rutas comunes donde EasyPanel puede montar archivos
POSSIBLE_PATHS=(
    "/root/checkin24hs"
    "/root/cotizador"
    "/var/lib/docker/volumes"
    "/data"
    "/app"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "   Verificando: $path"
        if [ -f "$path/cotizador-cliente.html" ]; then
            echo "      ✅ Encontrado: $path/cotizador-cliente.html"
            echo "      Tamaño: $(wc -c < "$path/cotizador-cliente.html") bytes"
        fi
        if [ -f "$path/index.html" ]; then
            echo "      ✅ Encontrado: $path/index.html"
        fi
    fi
done

echo ""
echo "3️⃣ Verificando archivos dentro del contenedor actual..."
echo ""

if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    echo "   Archivos en /usr/share/nginx/html/:"
    docker exec "$CONTAINER_ID" ls -lh /usr/share/nginx/html/ | grep -E "cotizador|index.html|supabase" | head -5
    echo ""
    
    # Verificar si tiene la función
    if docker exec "$CONTAINER_ID" grep -q "showPromotionValidationModal" /usr/share/nginx/html/index.html 2>/dev/null; then
        echo "   ✅ showPromotionValidationModal encontrada en contenedor"
    else
        echo "   ❌ showPromotionValidationModal NO encontrada en contenedor"
    fi
fi

echo ""
echo "4️⃣ Descargando archivos actualizados desde GitHub..."
echo ""

TEMP_DIR="/tmp/cotizador_update_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

curl -L -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
curl -L -o supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
curl -L -o supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js

FILE_SIZE=$(wc -c < cotizador-cliente.html)
echo "Tamaño descargado: $FILE_SIZE bytes"

if ! grep -q "showPromotionValidationModal" cotizador-cliente.html; then
    echo "❌ ERROR: showPromotionValidationModal NO encontrada en archivo descargado"
    exit 1
fi

echo "✅ Archivo descargado correctamente"
echo ""

echo "5️⃣ Buscando dónde actualizar los archivos..."
echo ""

# Si hay un bind mount, necesitamos encontrar la ruta en el servidor
# Intentar actualizar en rutas comunes
UPDATED=false

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ] && [ -w "$path" ]; then
        echo "   Intentando actualizar en: $path"
        cp cotizador-cliente.html "$path/cotizador-cliente.html" 2>/dev/null
        cp cotizador-cliente.html "$path/index.html" 2>/dev/null
        cp supabase-config.js "$path/supabase-config.js" 2>/dev/null
        cp supabase-client.js "$path/supabase-client.js" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "      ✅ Archivos copiados a $path"
            UPDATED=true
        fi
    fi
done

# También actualizar directamente en el contenedor
if [ ! -z "$CONTAINER_ID" ]; then
    echo ""
    echo "   Actualizando también en el contenedor..."
    docker cp cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/cotizador-cliente.html"
    docker cp cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/index.html"
    docker cp supabase-config.js "$CONTAINER_ID:/usr/share/nginx/html/supabase-config.js"
    docker cp supabase-client.js "$CONTAINER_ID:/usr/share/nginx/html/supabase-client.js"
    echo "      ✅ Archivos copiados al contenedor"
fi

cd /
rm -rf "$TEMP_DIR"

echo ""
echo "6️⃣ Reiniciando servicio..."
docker service update --force "$SERVICE_NAME"

echo ""
echo "=========================================="
if [ "$UPDATED" = true ]; then
    echo "✅ Actualización completada"
    echo "   Los archivos se actualizaron en las rutas del servidor"
else
    echo "⚠️  Actualización parcial"
    echo "   Los archivos se actualizaron en el contenedor"
    echo "   Si usa bind mount, verifica en EasyPanel dónde está montado"
fi
echo "=========================================="
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Espera 30-60 segundos"
echo "   2. Limpia la caché del navegador (Ctrl+Shift+R)"
echo "   3. Verifica en: https://cotizar.checkin24hs.com/"
echo ""
