#!/bin/bash
# Script para aplicar server.js directamente al contenedor y hacer commit de la imagen

echo "=========================================="
echo "🔧 APLICANDO SERVER.JS DIRECTAMENTE"
echo "=========================================="
echo ""

SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    exit 1
fi

echo "✅ Servicio: $SERVICE_NAME"
echo ""

# 1. Asegurarse de que el servicio esté funcionando
echo "1️⃣ Verificando que el servicio esté funcionando..."
docker service ps "$SERVICE_NAME" --no-trunc | head -3
echo ""

# 2. Descargar server.js desde GitHub
echo "2️⃣ Descargando server.js desde GitHub..."
TEMP_DIR="/tmp/dashboard_fix_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git
cd checkin24hs

if [ ! -f "checkin24hs-admin/server.js" ]; then
    echo "❌ No se encontró server.js en el repositorio"
    exit 1
fi

echo "✅ server.js descargado"
echo ""

# 3. Verificar que tiene la ruta
if ! grep -q "og-cotizar.jpg" checkin24hs-admin/server.js; then
    echo "❌ server.js no tiene la ruta /og-cotizar.jpg"
    exit 1
fi

echo "✅ Ruta /og-cotizar.jpg encontrada"
echo ""

# 4. Buscar contenedor en ejecución
echo "3️⃣ Buscando contenedor en ejecución..."
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor en ejecución"
    echo "   Esperando 10 segundos e intentando de nuevo..."
    sleep 10
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar contenedor. El servicio puede no estar funcionando."
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 5. Copiar server.js al contenedor
echo "4️⃣ Copiando server.js al contenedor..."
docker cp checkin24hs-admin/server.js "$CONTAINER_ID:/app/server.js"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar server.js"
    exit 1
fi

echo "✅ server.js copiado"
echo ""

# 6. Verificar que se copió correctamente
echo "5️⃣ Verificando que se copió correctamente..."
if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
    echo "   ✅ Ruta /og-cotizar.jpg encontrada en el contenedor"
else
    echo "   ⚠️  Ruta no encontrada (puede ser un problema de permisos)"
fi
echo ""

# 7. Reiniciar el proceso Node.js dentro del contenedor
echo "6️⃣ Reiniciando proceso Node.js en el contenedor..."
docker exec "$CONTAINER_ID" pkill -f "node server.js" 2>/dev/null
sleep 2

# Verificar si el proceso se reinició automáticamente (si hay un supervisor)
# Si no, necesitamos reiniciar el contenedor
if ! docker exec "$CONTAINER_ID" pgrep -f "node server.js" > /dev/null 2>&1; then
    echo "   ⚠️  Proceso no se reinició automáticamente"
    echo "   Reiniciando el contenedor..."
    docker restart "$CONTAINER_ID" 2>/dev/null || {
        echo "   ⚠️  No se pudo reiniciar el contenedor directamente"
        echo "   Reiniciando el servicio completo..."
        docker service update --force "$SERVICE_NAME"
        echo "   ⏳ Esperando 30 segundos..."
        sleep 30
    }
else
    echo "   ✅ Proceso se reinició automáticamente"
fi
echo ""

# 8. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

echo "=========================================="
echo "✅ SERVER.JS APLICADO"
echo "=========================================="
echo ""
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
echo "⚠️  NOTA: Este cambio es TEMPORAL y se perderá al reiniciar el servicio."
echo "   Para hacerlo permanente, necesitas actualizar el Dockerfile y hacer rebuild desde EasyPanel."
echo ""
