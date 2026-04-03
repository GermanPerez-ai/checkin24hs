#!/bin/bash

echo "=========================================="
echo "🔍 INVESTIGAR ORIGEN DEL ARCHIVO"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar si es un servicio de Docker Swarm
echo "=== 1. VERIFICAR SI ES DOCKER SWARM ==="
SERVICE_NAME=$(docker inspect "$CONTAINER" --format '{{index .Config.Labels "com.docker.swarm.service.name"}}' 2>/dev/null)
if [ -n "$SERVICE_NAME" ] && [ "$SERVICE_NAME" != "<no value>" ]; then
    echo "⚠️  Es un servicio de Docker Swarm: $SERVICE_NAME"
    echo "Esto significa que el archivo puede estar en la imagen Docker o en un volumen compartido"
    docker service inspect "$SERVICE_NAME" --pretty 2>/dev/null | grep -A 10 -E "Mounts|Image" | head -15
else
    echo "✅ No es un servicio de Docker Swarm (es un contenedor standalone)"
fi
echo ""

# 2. Verificar imagen Docker
echo "=== 2. VERIFICAR IMAGEN DOCKER ==="
IMAGE=$(docker inspect "$CONTAINER" --format '{{.Config.Image}}' 2>/dev/null)
echo "Imagen: $IMAGE"
echo ""

# 3. Verificar volúmenes montados
echo "=== 3. VERIFICAR VOLÚMENES MONTADOS ==="
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{if .RW}} (RW){{else}} (RO){{end}}{{"\n"}}{{end}}'
echo ""

# 4. Verificar si hay algún script de inicio
echo "=== 4. VERIFICAR SCRIPT DE INICIO ==="
docker exec "$CONTAINER" ls -lah /docker-entrypoint* /entrypoint* /start* 2>/dev/null | head -10
echo ""

# 5. Verificar si el archivo está en la imagen
echo "=== 5. VERIFICAR SI ESTÁ EN LA IMAGEN ==="
IMAGE_ID=$(docker inspect "$CONTAINER" --format '{{.Image}}' 2>/dev/null)
if [ -n "$IMAGE_ID" ]; then
    echo "Verificando archivo en la imagen Docker..."
    docker run --rm "$IMAGE_ID" grep -A 8 'class="header"' /app/dashboard.html 2>/dev/null | head -9 || echo "No se puede verificar en la imagen"
fi
echo ""

# 6. Verificar directorio de trabajo
echo "=== 6. DIRECTORIO DE TRABAJO ==="
docker exec "$CONTAINER" pwd
docker exec "$CONTAINER" ls -lah /app/ | head -15
echo ""

echo "=========================================="
echo "✅ Investigación completada"
echo "=========================================="
echo ""
echo "💡 Si es un servicio de Docker Swarm, necesitamos actualizar la imagen Docker"
echo "   o modificar el archivo en un volumen compartido"
echo ""
