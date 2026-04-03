#!/bin/bash
# Script para actualizar dashboard copiándolo directamente al contenedor

echo "🔄 Actualizando dashboard en contenedor..."
echo ""

# 1. Descargar archivo temporal
echo "📥 Descargando dashboard.html desde GitHub..."
cd /tmp
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -ne 0 ]; then
    echo "❌ Error al descargar archivo"
    exit 1
fi

# 2. Verificar Build Number
BUILD_NUM=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
echo "Build Number: $BUILD_NUM"

if [ "$BUILD_NUM" != "39" ]; then
    echo "⚠️  El build no es 39, es $BUILD_NUM"
else
    echo "✅ Build #39 confirmado"
fi

# 3. Encontrar contenedor
echo ""
echo "🔍 Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "Buscando por servicio..."
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar el contenedor"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"

# 4. Copiar archivo al contenedor
echo ""
echo "📋 Copiando archivo al contenedor..."
docker cp /tmp/dashboard.html ${CONTAINER_ID}:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado al contenedor"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi

# 5. Verificar que se copió
echo ""
echo "🔍 Verificando archivo en contenedor..."
docker exec ${CONTAINER_ID} grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*" /app/dashboard.html | head -1

# 6. Reiniciar contenedor (si es necesario, algunos servicios se recargan automáticamente)
echo ""
echo "⚠️  Si el archivo no se actualiza, reinicia el contenedor:"
echo "   docker restart $CONTAINER_ID"
echo ""
echo "O reinicia el servicio:"
echo "   docker service update --force checkin24hs_dashboard"

# 7. Limpiar archivo temporal
rm -f /tmp/dashboard.html

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
