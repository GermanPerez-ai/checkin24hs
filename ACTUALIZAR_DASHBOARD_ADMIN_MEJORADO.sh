#!/bin/bash
# Script mejorado para actualizar checkin24hs-admin desde GitHub
# Copia server.js durante el reinicio cuando el contenedor está detenido

echo "=========================================="
echo "🔄 ACTUALIZANDO DASHBOARD ADMIN (MEJORADO)"
echo "=========================================="
echo ""

# 1. Buscar servicio del dashboard
echo "1️⃣ Buscando servicio del dashboard..."
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    docker service ls --format "{{.Name}}" | head -10
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Descargar código desde GitHub
echo "2️⃣ Descargando código desde GitHub..."
TEMP_DIR="/tmp/dashboard_admin_update_$(date +%s)"
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
    echo "❌ checkin24hs-admin/server.js no encontrado en el repositorio"
    exit 1
fi

echo "✅ Código descargado"
echo ""

# 3. Escalar el servicio a 0 (detener todos los contenedores)
echo "3️⃣ Deteniendo servicio temporalmente para copiar archivo..."
docker service scale "$SERVICE_NAME=0"

# Esperar a que se detenga completamente
echo "   ⏳ Esperando 10 segundos para que el servicio se detenga..."
sleep 10

# 4. Buscar contenedor detenido o crear uno temporal
echo "4️⃣ Buscando contenedor detenido..."
STOPPED_CONTAINER=$(docker ps -a --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$STOPPED_CONTAINER" ]; then
    echo "   ⚠️  No se encontró contenedor detenido, creando uno temporal..."
    # Obtener la imagen del servicio
    IMAGE=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
    # Crear contenedor temporal
    TEMP_CONTAINER=$(docker create "$IMAGE")
    STOPPED_CONTAINER=$TEMP_CONTAINER
    echo "   ✅ Contenedor temporal creado: $TEMP_CONTAINER"
fi

echo "✅ Contenedor encontrado: $STOPPED_CONTAINER"
echo ""

# 5. Copiar server.js al contenedor detenido
echo "5️⃣ Copiando server.js al contenedor..."
docker cp checkin24hs-admin/server.js "$STOPPED_CONTAINER:/app/server.js"

if [ $? -eq 0 ]; then
    echo "   ✅ server.js copiado exitosamente"
    
    # Verificar que se copió
    if docker exec "$STOPPED_CONTAINER" test -f /app/server.js 2>/dev/null; then
        echo "   ✅ Archivo verificado en el contenedor"
    fi
else
    echo "   ❌ Error al copiar server.js"
    # Si creamos un contenedor temporal, limpiarlo
    if [ ! -z "$TEMP_CONTAINER" ]; then
        docker rm "$TEMP_CONTAINER" 2>/dev/null
    fi
    # Restaurar el servicio
    docker service scale "$SERVICE_NAME=1"
    exit 1
fi
echo ""

# 6. Si creamos un contenedor temporal, necesitamos commitear la imagen
if [ ! -z "$TEMP_CONTAINER" ]; then
    echo "6️⃣ Creando nueva imagen con los cambios..."
    NEW_IMAGE_TAG="checkin24hs/dashboard:updated-$(date +%s)"
    docker commit "$TEMP_CONTAINER" "$NEW_IMAGE_TAG"
    docker rm "$TEMP_CONTAINER"
    
    echo "   ✅ Nueva imagen creada: $NEW_IMAGE_TAG"
    echo "   ⚠️  Nota: Esta imagen no se usará automáticamente"
    echo "   Necesitarás actualizar el servicio para usar esta imagen"
    echo ""
fi

# 7. Restaurar el servicio
echo "7️⃣ Reiniciando servicio..."
docker service scale "$SERVICE_NAME=1"

if [ $? -eq 0 ]; then
    echo "   ✅ Servicio reiniciado"
    echo "   ⏳ Esperando 30 segundos para que el servicio se inicie..."
    sleep 30
else
    echo "   ❌ Error al reiniciar el servicio"
    exit 1
fi
echo ""

# 8. Verificar que server.js tiene la ruta
echo "8️⃣ Verificando que server.js tiene la ruta /og-cotizar.jpg..."
NEW_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER" ]; then
    if docker exec "$NEW_CONTAINER" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
        echo "   ✅ Ruta /og-cotizar.jpg encontrada en server.js"
    else
        echo "   ⚠️  Ruta /og-cotizar.jpg NO encontrada"
        echo "   Esto puede ser porque el contenedor se recreó desde la imagen original"
    fi
else
    echo "   ⚠️  No se pudo encontrar el contenedor nuevo para verificar"
fi
echo ""

# 9. Limpiar
echo "9️⃣ Limpiando archivos temporales..."
cd /
rm -rf "$TEMP_DIR"
echo "   ✅ Archivos temporales eliminados"
echo ""

echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANTE:"
echo "   Si el contenedor se recreó desde la imagen original, los cambios"
echo "   se perderán. En ese caso, necesitas:"
echo "   1. Actualizar el Dockerfile para incluir server.js"
echo "   2. Hacer push a GitHub"
echo "   3. Rebuild desde EasyPanel"
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Prueba acceder a: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "   2. Si da 404, necesitarás actualizar el Dockerfile y hacer rebuild"
echo ""
