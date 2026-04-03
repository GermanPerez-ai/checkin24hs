#!/bin/bash
# Script para reconstruir la imagen Docker manualmente
# SOLO usar si tienes acceso al código en el servidor

echo "=========================================="
echo "🔨 Reconstruyendo Imagen Docker Manualmente"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

# Verificar que estamos en el directorio correcto
if [ ! -f "Dockerfile" ] && [ ! -f "/root/checkin24hs/Dockerfile" ]; then
    echo "❌ No se encontró Dockerfile"
    echo "   Buscando Dockerfile..."
    DOCKERFILE_PATH=$(find /root -name "Dockerfile" -type f 2>/dev/null | head -1)
    if [ ! -z "$DOCKERFILE_PATH" ]; then
        echo "   ✅ Dockerfile encontrado en: $DOCKERFILE_PATH"
        cd "$(dirname "$DOCKERFILE_PATH")"
    else
        echo "   ❌ Dockerfile no encontrado"
        echo ""
        echo "   Este script requiere acceso al código en el servidor"
        echo "   Si EasyPanel está gestionando el código, usa la OPCIÓN 1 en EasyPanel"
        exit 1
    fi
else
    if [ -f "/root/checkin24hs/Dockerfile" ]; then
        cd /root/checkin24hs
    fi
fi

echo "Directorio de trabajo: $(pwd)"
echo ""

# Verificar que tenemos el código más reciente
echo "1️⃣ Verificando código más reciente..."
if [ -d ".git" ]; then
    echo "   ✅ Repositorio Git encontrado"
    echo "   Actualizando desde GitHub..."
    git fetch origin main 2>/dev/null
    git reset --hard origin/main 2>/dev/null
    echo "   ✅ Código actualizado"
else
    echo "   ⚠️ No es un repositorio Git"
    echo "   Asegúrate de que el código esté actualizado manualmente"
fi

echo ""

# Verificar BUILD_TIMESTAMP en dashboard.html
echo "2️⃣ Verificando BUILD_TIMESTAMP en dashboard.html..."
if [ -f "dashboard.html" ]; then
    BUILD_TS=$(grep -oP "window\.BUILD_TIMESTAMP = ['\"]([^'\"]+)['\"]" dashboard.html | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | tr -d "'\"")
    if [ ! -z "$BUILD_TS" ]; then
        echo "   ✅ BUILD_TIMESTAMP: $BUILD_TS"
    else
        echo "   ⚠️ BUILD_TIMESTAMP no encontrado"
    fi
else
    echo "   ❌ dashboard.html no encontrado"
    exit 1
fi

echo ""

# Obtener imagen actual del servicio
echo "3️⃣ Obteniendo imagen actual del servicio..."
SERVICE_IMAGE=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)

if [ -z "$SERVICE_IMAGE" ]; then
    echo "❌ No se pudo obtener la imagen del servicio"
    exit 1
fi

echo "   Imagen actual: $SERVICE_IMAGE"
echo ""

# Extraer nombre de la imagen sin tag
IMAGE_NAME=$(echo "$SERVICE_IMAGE" | cut -d: -f1)
IMAGE_TAG=$(echo "$SERVICE_IMAGE" | cut -d: -f2)

if [ -z "$IMAGE_TAG" ] || [ "$IMAGE_TAG" = "$SERVICE_IMAGE" ]; then
    IMAGE_TAG="latest"
fi

echo "   Nombre de imagen: $IMAGE_NAME"
echo "   Tag: $IMAGE_TAG"
echo ""

# Construir nueva imagen
echo "4️⃣ Construyendo nueva imagen Docker (sin caché)..."
echo "   Esto puede tardar varios minutos..."
echo ""

docker build -t "$IMAGE_NAME:$IMAGE_TAG" --no-cache .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen"
    exit 1
fi

echo ""
echo "✅ Imagen construida correctamente"
echo ""

# Verificar nueva imagen
echo "5️⃣ Verificando nueva imagen..."
TEMP_CONTAINER=$(docker create "$IMAGE_NAME:$IMAGE_TAG" 2>/dev/null)
if [ ! -z "$TEMP_CONTAINER" ]; then
    NEW_BUILD_TS=$(docker exec "$TEMP_CONTAINER" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")
    docker rm "$TEMP_CONTAINER" 2>/dev/null
    
    if [ "$NEW_BUILD_TS" != "NO" ]; then
        echo "   ✅ BUILD_TIMESTAMP en nueva imagen: $NEW_BUILD_TS"
        if [ "$NEW_BUILD_TS" = "$BUILD_TS" ]; then
            echo "   ✅ Coincide con el código actual"
        else
            echo "   ⚠️ No coincide con el código actual"
        fi
    fi
fi

echo ""

# Actualizar servicio
echo "6️⃣ Actualizando servicio para usar la nueva imagen..."
echo "   Esto reiniciará el servicio y creará nuevos contenedores"
echo ""

docker service update --image "$IMAGE_NAME:$IMAGE_TAG" "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "⏳ Esperando 30 segundos para que el servicio se reinicie..."
    sleep 30
    
    # Verificar nuevo contenedor
    NEW_CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
    if [ ! -z "$NEW_CONTAINER_ID" ]; then
        echo "   Nuevo contenedor: $NEW_CONTAINER_ID"
        
        # Verificar archivo en nuevo contenedor
        NEW_BUILD_TS_CONTAINER=$(docker exec "$NEW_CONTAINER_ID" grep "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | head -1 | grep -oP "['\"]([^'\"]+)['\"]" | head -1 | tr -d "'\"" || echo "NO")
        if [ "$NEW_BUILD_TS_CONTAINER" != "NO" ]; then
            echo "   ✅ BUILD_TIMESTAMP en nuevo contenedor: $NEW_BUILD_TS_CONTAINER"
        fi
    fi
else
    echo "❌ Error al actualizar el servicio"
    exit 1
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "✅ Imagen reconstruida y servicio actualizado"
echo ""
echo "🌐 Prueba el dashboard:"
echo "   https://dashboard.checkin24hs.com"
echo ""
echo "   ⚠️ IMPORTANTE:"
echo "   1. Abre en ventana de incógnito (Ctrl+Shift+N)"
echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
echo "   3. Verifica que los Material Icons aparezcan correctamente"
echo ""
echo "📝 NOTA:"
echo "   Esta es una solución temporal. Para una solución permanente,"
echo "   configura EasyPanel para que reconstruya automáticamente"
echo "   cuando hay cambios en GitHub."
echo ""
