#!/bin/bash
# Script para verificar y actualizar la imagen Docker que usa el servicio

echo "=========================================="
echo "🔍 Verificando Imagen Docker del Servicio"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

# 1. Verificar qué imagen está usando el servicio
echo "1️⃣ Verificando qué imagen está usando el servicio..."
SERVICE_IMAGE=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)

if [ -z "$SERVICE_IMAGE" ]; then
    echo "❌ No se pudo obtener la imagen del servicio"
    exit 1
fi

echo "   Imagen actual: $SERVICE_IMAGE"
echo ""

# 2. Verificar si la imagen existe localmente
echo "2️⃣ Verificando si la imagen existe localmente..."
IMAGE_EXISTS=$(docker images "$SERVICE_IMAGE" --format "{{.Repository}}:{{.Tag}}" | head -1)

if [ ! -z "$IMAGE_EXISTS" ]; then
    echo "   ✅ Imagen existe localmente: $IMAGE_EXISTS"
    IMAGE_DATE=$(docker images "$SERVICE_IMAGE" --format "{{.CreatedAt}}" | head -1)
    echo "   Fecha de creación: $IMAGE_DATE"
else
    echo "   ⚠️ Imagen no existe localmente (puede estar en el registry)"
fi

echo ""

# 3. Verificar contenedores actuales
echo "3️⃣ Verificando contenedores actuales..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    CONTAINER_IMAGE=$(docker inspect "$CONTAINER_ID" --format '{{.Config.Image}}' 2>/dev/null)
    echo "   Contenedor actual: $CONTAINER_ID"
    echo "   Imagen del contenedor: $CONTAINER_IMAGE"
    
    if [ "$CONTAINER_IMAGE" != "$SERVICE_IMAGE" ]; then
        echo "   ⚠️ La imagen del contenedor NO coincide con la del servicio"
    fi
fi

echo ""

# 4. Verificar archivo dashboard.html en la imagen
echo "4️⃣ Verificando archivo dashboard.html en la imagen..."
if [ ! -z "$IMAGE_EXISTS" ]; then
    # Crear un contenedor temporal desde la imagen
    TEMP_CONTAINER=$(docker create "$SERVICE_IMAGE" 2>/dev/null)
    if [ ! -z "$TEMP_CONTAINER" ]; then
        IMAGE_FILE_SIZE=$(docker cp "$TEMP_CONTAINER:/app/dashboard.html" - 2>/dev/null | wc -c || echo "0")
        IMAGE_BUILD_TS=$(docker exec "$TEMP_CONTAINER" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")
        docker rm "$TEMP_CONTAINER" 2>/dev/null
        
        echo "   Tamaño del archivo en la imagen: $IMAGE_FILE_SIZE bytes"
        echo "   BUILD_TIMESTAMP en la imagen: $IMAGE_BUILD_TS"
    else
        echo "   ⚠️ No se pudo crear contenedor temporal para verificar"
    fi
else
    echo "   ⚠️ No se puede verificar (imagen no existe localmente)"
fi

echo ""

# 5. Comparar con GitHub
echo "5️⃣ Comparando con versión en GitHub..."
TEMP_DIR="/tmp/dashboard_github_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

curl -L -s "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o github_dashboard.html 2>/dev/null

if [ -f "github_dashboard.html" ]; then
    GITHUB_SIZE=$(stat -c%s github_dashboard.html 2>/dev/null || stat -f%z github_dashboard.html 2>/dev/null)
    GITHUB_BUILD=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" github_dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    
    echo "   GitHub: $GITHUB_SIZE bytes, BUILD: $GITHUB_BUILD"
    
    if [ ! -z "$IMAGE_BUILD_TS" ] && [ "$IMAGE_BUILD_TS" != "NO" ]; then
        if [ "$IMAGE_BUILD_TS" = "$GITHUB_BUILD" ]; then
            echo "   ✅ La imagen tiene la misma versión que GitHub"
        else
            echo "   ❌ La imagen tiene versión diferente a GitHub"
            echo "      Imagen: $IMAGE_BUILD_TS"
            echo "      GitHub: $GITHUB_BUILD"
        fi
    fi
fi

rm -rf "$TEMP_DIR"

echo ""

# 6. Verificar Dockerfile
echo "6️⃣ Verificando Dockerfile..."
if [ -f "/root/checkin24hs/Dockerfile" ]; then
    echo "   ✅ Dockerfile encontrado en /root/checkin24hs/Dockerfile"
    DOCKERFILE_CONTENT=$(cat /root/checkin24hs/Dockerfile 2>/dev/null | head -20)
    echo "   Primeras líneas del Dockerfile:"
    echo "$DOCKERFILE_CONTENT" | sed 's/^/      /'
else
    echo "   ⚠️ Dockerfile no encontrado en /root/checkin24hs/"
    echo "   Buscando en otras ubicaciones..."
    DOCKERFILE_PATH=$(find /root -name "Dockerfile" -type f 2>/dev/null | grep -i dashboard | head -1)
    if [ ! -z "$DOCKERFILE_PATH" ]; then
        echo "   ✅ Dockerfile encontrado en: $DOCKERFILE_PATH"
    else
        echo "   ❌ Dockerfile no encontrado"
    fi
fi

echo ""

# 7. Verificar si EasyPanel está gestionando el build
echo "7️⃣ Verificando configuración de EasyPanel..."
EASYPANEL_PATH=$(find /var/lib/easypanel -name "*dashboard*" -type d 2>/dev/null | head -1)
if [ ! -z "$EASYPANEL_PATH" ]; then
    echo "   ✅ Ruta de EasyPanel encontrada: $EASYPANEL_PATH"
    if [ -f "$EASYPANEL_PATH/Dockerfile" ]; then
        echo "   ✅ Dockerfile de EasyPanel encontrado"
    fi
else
    echo "   ⚠️ Ruta de EasyPanel no encontrada"
fi

echo ""

echo "=========================================="
echo "📋 RESUMEN Y SOLUCIONES"
echo "=========================================="
echo ""

echo "📊 Estado actual:"
echo "   - Imagen del servicio: $SERVICE_IMAGE"
if [ ! -z "$IMAGE_BUILD_TS" ] && [ "$IMAGE_BUILD_TS" != "NO" ]; then
    echo "   - BUILD_TIMESTAMP en imagen: $IMAGE_BUILD_TS"
fi
if [ ! -z "$GITHUB_BUILD" ]; then
    echo "   - BUILD_TIMESTAMP en GitHub: $GITHUB_BUILD"
fi
echo ""

if [ ! -z "$IMAGE_BUILD_TS" ] && [ ! -z "$GITHUB_BUILD" ] && [ "$IMAGE_BUILD_TS" != "$GITHUB_BUILD" ]; then
    echo "❌ PROBLEMA DETECTADO:"
    echo "   La imagen Docker tiene una versión antigua"
    echo "   Cada vez que Docker Swarm crea un nuevo contenedor, usa esta imagen antigua"
    echo ""
    echo "🔧 SOLUCIONES:"
    echo ""
    echo "OPCIÓN 1: Reconstruir imagen en EasyPanel (RECOMENDADO)"
    echo "   1. Ve a EasyPanel → Proyecto checkin24hs → Servicio dashboard"
    echo "   2. Haz clic en 'Build' o 'Rebuild'"
    echo "   3. Marca 'Build without cache' o 'Sin caché'"
    echo "   4. Espera 3-5 minutos"
    echo ""
    echo "OPCIÓN 2: Reconstruir imagen manualmente"
    echo "   Si tienes acceso al código en el servidor:"
    echo "   cd /root/checkin24hs"
    echo "   docker build -t $SERVICE_IMAGE --no-cache ."
    echo "   docker service update --image $SERVICE_IMAGE $DASHBOARD_SERVICE"
    echo ""
    echo "OPCIÓN 3: Forzar pull de imagen desde registry"
    echo "   docker service update --image $SERVICE_IMAGE:latest $DASHBOARD_SERVICE"
    echo "   (Solo funciona si EasyPanel está construyendo y subiendo la imagen)"
    echo ""
else
    if [ ! -z "$IMAGE_BUILD_TS" ] && [ "$IMAGE_BUILD_TS" = "$GITHUB_BUILD" ]; then
        echo "✅ La imagen tiene la versión correcta"
        echo ""
        echo "   Si aún ves versión antigua en el navegador:"
        echo "   1. Es problema de caché del navegador"
        echo "   2. Abre en ventana de incógnito (Ctrl+Shift+N)"
        echo "   3. Presiona Ctrl+Shift+R para forzar recarga"
    else
        echo "⚠️ No se pudo verificar completamente"
        echo "   Ejecuta la OPCIÓN 1 (reconstruir en EasyPanel) para asegurarte"
    fi
fi

echo ""
