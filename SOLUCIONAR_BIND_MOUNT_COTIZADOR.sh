#!/bin/bash
# Solucionar problema de bind mount en cotizador

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

echo "=========================================="
echo "🔧 SOLUCIONAR BIND MOUNT COTIZADOR"
echo "=========================================="
echo ""

echo "1️⃣ Verificando configuración actual del servicio..."
echo ""
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>/dev/null

echo ""
echo "2️⃣ Verificando archivos en /root/checkin24hs/..."
echo ""
ls -lh /root/checkin24hs/ | grep -E "cotizador|index.html|supabase"

echo ""
echo "3️⃣ Verificando qué archivos ve el contenedor..."
echo ""
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Archivos en /usr/share/nginx/html/:"
    docker exec "$CONTAINER_ID" ls -lh /usr/share/nginx/html/ | grep -E "cotizador|index.html|supabase"
    echo ""
    echo "Verificando si /usr/share/nginx/html/ es un mount point..."
    docker exec "$CONTAINER_ID" mount | grep "/usr/share/nginx/html"
fi

echo ""
echo "4️⃣ Actualizando index.html en /root/checkin24hs/..."
echo ""
if [ -f "/root/checkin24hs/cotizador-cliente.html" ]; then
    cp /root/checkin24hs/cotizador-cliente.html /root/checkin24hs/index.html
    if [ $? -eq 0 ]; then
        echo "✅ index.html actualizado en /root/checkin24hs/"
    else
        echo "❌ Error al actualizar index.html"
    fi
fi

echo ""
echo "5️⃣ Forzando actualización en contenedor..."
echo ""
if [ ! -z "$CONTAINER_ID" ]; then
    # Descargar archivo actualizado
    TEMP_DIR="/tmp/cotizador_fix_$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    curl -L -s -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
    
    # Copiar directamente al contenedor
    docker cp cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/cotizador-cliente.html"
    docker cp cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/index.html"
    docker cp /root/checkin24hs/supabase-config.js "$CONTAINER_ID:/usr/share/nginx/html/supabase-config.js" 2>/dev/null
    docker cp /root/checkin24hs/supabase-client.js "$CONTAINER_ID:/usr/share/nginx/html/supabase-client.js" 2>/dev/null
    
    cd /
    rm -rf "$TEMP_DIR"
    
    echo "✅ Archivos copiados directamente al contenedor"
fi

echo ""
echo "6️⃣ Verificando después de la actualización..."
echo ""
if [ ! -z "$CONTAINER_ID" ]; then
    if docker exec "$CONTAINER_ID" grep -q "showPromotionValidationModal" /usr/share/nginx/html/index.html 2>/dev/null; then
        echo "✅ showPromotionValidationModal encontrada en contenedor"
        CONTAINER_SIZE=$(docker exec "$CONTAINER_ID" stat -c %s /usr/share/nginx/html/index.html 2>/dev/null)
        echo "   Tamaño: $CONTAINER_SIZE bytes"
    else
        echo "❌ showPromotionValidationModal NO encontrada - puede haber un problema con el bind mount"
    fi
fi

echo ""
echo "7️⃣ Reiniciando servicio..."
echo ""
docker service update --force "$SERVICE_NAME"

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANTE: Si el problema persiste, puede ser que:"
echo "   1. El bind mount esté montado en otra ruta dentro del contenedor"
echo "   2. El servicio esté usando la imagen Docker en lugar del bind mount"
echo "   3. Necesites verificar en EasyPanel la configuración del bind mount"
echo ""
