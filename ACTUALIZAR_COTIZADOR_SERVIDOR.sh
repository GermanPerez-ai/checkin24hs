#!/bin/bash
# Script rápido para actualizar cotizador-cliente.html en el servidor

echo "🔄 Actualizando cotizador desde GitHub..."

# Buscar contenedor del cotizador
CONTAINER_ID=$(docker ps --filter "name=cotizador" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ Buscando en todos los contenedores..."
    CONTAINER_ID=$(docker ps --format "{{.ID}}" | head -1)
    echo "📋 Contenedores disponibles:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
    echo ""
    read -p "Ingresa el ID del contenedor: " CONTAINER_ID
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"

# Descargar archivo desde GitHub
echo "📥 Descargando cotizador-cliente.html desde GitHub..."
curl -L -o /tmp/cotizador-cliente.html "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html"

if [ ! -f /tmp/cotizador-cliente.html ]; then
    echo "❌ Error al descargar el archivo"
    exit 1
fi

# Copiar al contenedor (tanto como cotizador-cliente.html como index.html)
echo "📤 Copiando archivos al contenedor..."
docker cp /tmp/cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/cotizador-cliente.html"
docker cp /tmp/cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/index.html"

echo "✅ Archivos actualizados"
echo ""
echo "🌐 Prueba acceder a: https://cotizar.checkin24hs.com/"
echo "   Verifica que el cálculo de check-out funcione correctamente"
