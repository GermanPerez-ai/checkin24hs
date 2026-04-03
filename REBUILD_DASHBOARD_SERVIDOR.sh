#!/bin/bash
# Script para reconstruir la imagen del dashboard directamente en el servidor

echo "=========================================="
echo "🔨 REBUILD DASHBOARD EN SERVIDOR"
echo "=========================================="
echo ""

# 1. Buscar servicio del dashboard
echo "1️⃣ Buscando servicio del dashboard..."
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Obtener imagen actual
echo "2️⃣ Obteniendo imagen actual del servicio..."
CURRENT_IMAGE=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
echo "   Imagen actual: $CURRENT_IMAGE"
echo ""

# 3. Descargar código desde GitHub
echo "3️⃣ Descargando código desde GitHub..."
TEMP_DIR="/tmp/dashboard_rebuild_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

if [ -d "checkin24hs" ]; then
    cd checkin24hs
    git pull origin main
else
    git clone https://github.com/GermanPerez-ai/checkin24hs.git
    cd checkin24hs
fi

if [ ! -f "checkin24hs-admin/server.js" ]; then
    echo "❌ checkin24hs-admin/server.js no encontrado"
    exit 1
fi

echo "✅ Código descargado"
echo ""

# 4. Verificar que server.js tiene la ruta
echo "4️⃣ Verificando que server.js tiene la ruta /og-cotizar.jpg..."
if grep -q "og-cotizar.jpg" checkin24hs-admin/server.js; then
    echo "   ✅ Ruta /og-cotizar.jpg encontrada en server.js"
else
    echo "   ❌ Ruta /og-cotizar.jpg NO encontrada"
    exit 1
fi
echo ""

# 5. Construir nueva imagen
echo "5️⃣ Construyendo nueva imagen Docker..."
cd checkin24hs-admin

NEW_IMAGE_TAG="checkin24hs/dashboard:latest-$(date +%Y%m%d-%H%M%S)"
echo "   Tag de nueva imagen: $NEW_IMAGE_TAG"
echo ""

docker build -t "$NEW_IMAGE_TAG" -f Dockerfile .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen"
    exit 1
fi

echo "✅ Imagen construida exitosamente"
echo ""

# 6. Actualizar el servicio con la nueva imagen
echo "6️⃣ Actualizando servicio con la nueva imagen..."
docker service update --image "$NEW_IMAGE_TAG" "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Servicio actualizado"
    echo "   ⏳ Esperando 30 segundos para que el servicio se reinicie..."
    sleep 30
else
    echo "   ❌ Error al actualizar el servicio"
    exit 1
fi
echo ""

# 7. Verificar que el nuevo contenedor tiene server.js con la ruta
echo "7️⃣ Verificando que el nuevo contenedor tiene la ruta..."
NEW_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER" ]; then
    if docker exec "$NEW_CONTAINER" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
        echo "   ✅ Ruta /og-cotizar.jpg encontrada en el nuevo contenedor"
    else
        echo "   ⚠️  Ruta /og-cotizar.jpg NO encontrada en el nuevo contenedor"
    fi
else
    echo "   ⚠️  No se pudo encontrar el nuevo contenedor"
fi
echo ""

# 8. Limpiar
echo "8️⃣ Limpiando archivos temporales..."
cd /
rm -rf "$TEMP_DIR"
echo "   ✅ Archivos temporales eliminados"
echo ""

echo "=========================================="
echo "✅ REBUILD COMPLETADO"
echo "=========================================="
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Espera 1-2 minutos adicionales para que el servicio se estabilice"
echo "   2. Prueba acceder a: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "   3. Debería mostrar una imagen de hotel"
echo ""
echo "📋 Para verificar:"
echo "   curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "   docker service ps $SERVICE_NAME"
echo ""
