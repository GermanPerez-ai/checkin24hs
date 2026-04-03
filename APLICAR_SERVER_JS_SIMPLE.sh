#!/bin/bash
# Script simple para aplicar server.js directamente al contenedor

echo "=========================================="
echo "🔧 APLICANDO SERVER.JS AL CONTENEDOR"
echo "=========================================="
echo ""

# 1. Buscar contenedor
SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor en ejecución"
    echo "   Esperando 5 segundos..."
    sleep 5
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar contenedor"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 2. Descargar server.js desde GitHub
echo "2️⃣ Descargando server.js desde GitHub..."
TEMP_DIR="/tmp/dashboard_fix_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | grep -v "Cloning\|remote\|Receiving\|Resolving" | head -5

if [ ! -f "checkin24hs/checkin24hs-admin/server.js" ]; then
    echo "❌ No se encontró server.js"
    exit 1
fi

echo "✅ server.js descargado"
echo ""

# 3. Verificar que tiene la ruta
if ! grep -q "og-cotizar.jpg" checkin24hs/checkin24hs-admin/server.js; then
    echo "❌ server.js no tiene la ruta /og-cotizar.jpg"
    exit 1
fi

echo "✅ Ruta /og-cotizar.jpg encontrada"
echo ""

# 4. Copiar al contenedor
echo "4️⃣ Copiando server.js al contenedor..."
docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/app/server.js"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar server.js"
    exit 1
fi

echo "✅ server.js copiado exitosamente"
echo ""

# 5. Verificar que se copió
echo "5️⃣ Verificando que se copió correctamente..."
if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
    echo "   ✅ Ruta /og-cotizar.jpg encontrada en el contenedor"
else
    echo "   ⚠️  Ruta no encontrada (puede ser problema de permisos)"
fi
echo ""

# 6. Reiniciar el proceso Node.js
echo "6️⃣ Reiniciando proceso Node.js..."
# Intentar matar el proceso Node.js para que se reinicie automáticamente
docker exec "$CONTAINER_ID" pkill -f "node.*server.js" 2>/dev/null
sleep 3

# Verificar si se reinició
if docker exec "$CONTAINER_ID" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Proceso Node.js está corriendo"
else
    echo "   ⚠️  Proceso no se reinició automáticamente"
    echo "   Reiniciando el servicio completo..."
    docker service update --force "$SERVICE_NAME"
    echo "   ⏳ Esperando 20 segundos..."
    sleep 20
fi
echo ""

# 7. Limpiar
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
echo "⚠️  NOTA: Este cambio es TEMPORAL."
echo "   Se perderá al reiniciar el servicio."
echo "   Para hacerlo permanente, asegúrate de que server.js esté en GitHub"
echo "   y haz rebuild desde EasyPanel."
echo ""
