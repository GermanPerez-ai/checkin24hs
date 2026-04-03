#!/bin/bash
# Script robusto para aplicar server.js

echo "=========================================="
echo "🔧 APLICANDO SERVER.JS (MÉTODO ROBUSTO)"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 1. Descargar server.js
echo "1️⃣ Descargando server.js desde GitHub..."
TEMP_DIR="/tmp/dashboard_fix_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

if [ ! -f "checkin24hs/checkin24hs-admin/server.js" ]; then
    echo "❌ No se encontró server.js"
    exit 1
fi

echo "✅ server.js descargado"
echo ""

# 2. Copiar a ubicación temporal
echo "2️⃣ Copiando a ubicación temporal..."
docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/tmp/server.js.new"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar"
    exit 1
fi

echo "✅ Archivo copiado a /tmp/server.js.new"
echo ""

# 3. Detener Node.js de forma más agresiva
echo "3️⃣ Deteniendo Node.js de forma agresiva..."
docker exec "$CONTAINER_ID" pkill -9 node 2>/dev/null
docker exec "$CONTAINER_ID" killall -9 node 2>/dev/null
sleep 3

# Verificar que se detuvo
if docker exec "$CONTAINER_ID" pgrep node > /dev/null 2>&1; then
    echo "   ⚠️  Proceso aún corriendo, forzando detención del contenedor..."
    # Reiniciar el servicio para que se detenga completamente
    docker service update --force "$SERVICE_NAME" > /dev/null 2>&1
    echo "   ⏳ Esperando 10 segundos para que el contenedor se reinicie..."
    sleep 10
    
    # Buscar nuevo contenedor
    NEW_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
    if [ ! -z "$NEW_CONTAINER" ] && [ "$NEW_CONTAINER" != "$CONTAINER_ID" ]; then
        CONTAINER_ID="$NEW_CONTAINER"
        echo "   ✅ Nuevo contenedor: $CONTAINER_ID"
        # Copiar de nuevo al nuevo contenedor
        docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/tmp/server.js.new"
    fi
    sleep 2
else
    echo "   ✅ Proceso Node.js detenido"
fi
echo ""

# 4. Intentar copiar directamente usando cp dentro del contenedor
echo "4️⃣ Copiando archivo usando cp dentro del contenedor..."
docker exec "$CONTAINER_ID" sh -c "cp /tmp/server.js.new /app/server.js" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente usando cp"
else
    echo "   ⚠️  Error con cp, intentando con cat..."
    # Intentar con cat
    docker exec -i "$CONTAINER_ID" sh -c "cat > /app/server.js" < checkin24hs/checkin24hs-admin/server.js 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivo copiado exitosamente usando cat"
    else
        echo "❌ Error al copiar el archivo"
        echo ""
        echo "   El archivo puede estar montado como volumen o tener permisos especiales."
        echo "   Solución permanente: Actualiza el Dockerfile y haz rebuild desde EasyPanel."
        exit 1
    fi
fi
echo ""

# 5. Verificar que se copió
echo "5️⃣ Verificando que se copió correctamente..."
if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
    echo "✅ Ruta /og-cotizar.jpg confirmada"
else
    echo "⚠️  Ruta no encontrada"
fi
echo ""

# 6. Reiniciar servicio
echo "6️⃣ Reiniciando servicio..."
docker service update --force "$SERVICE_NAME" > /dev/null 2>&1
echo "✅ Servicio reiniciado"
echo "⏳ Esperando 30 segundos..."
sleep 30
echo ""

# 7. Verificación final
echo "7️⃣ Verificación final..."
FINAL_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$FINAL_CONTAINER" ]; then
    if docker exec "$FINAL_CONTAINER" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
        echo "✅ Ruta /og-cotizar.jpg encontrada"
    else
        echo "⚠️  Ruta no encontrada"
    fi
    
    if docker exec "$FINAL_CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "✅ Proceso Node.js está corriendo"
    else
        echo "⚠️  Proceso Node.js no está corriendo"
    fi
else
    echo "⚠️  No se encontró contenedor"
fi
echo ""

# 8. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "🌐 Prueba: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
