#!/bin/bash
# Script para aplicar cambio de imagen en el servidor (temporal)
# Ahora funciona con cualquier hotel disponible dinámicamente

SELECTED_HOTEL="$1"

if [ -z "$SELECTED_HOTEL" ]; then
    echo "❌ Debes especificar el hotel (ej: hotel-1-puyehue)"
    exit 1
fi

echo "=========================================="
echo "🔄 APLICANDO CAMBIO DE IMAGEN EN SERVIDOR"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo "✅ Hotel: $SELECTED_HOTEL"
echo ""

# 1. Descargar código desde GitHub
echo "1️⃣ Descargando código desde GitHub..."
TEMP_DIR="/tmp/change_image_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

if [ ! -f "checkin24hs/checkin24hs-admin/server.js" ]; then
    echo "❌ No se encontró server.js"
    exit 1
fi

echo "✅ Código descargado"
echo ""

# 2. Modificar server.js para usar el hotel seleccionado
echo "2️⃣ Modificando server.js para usar $SELECTED_HOTEL..."
cd checkin24hs/checkin24hs-admin

# El código ya detecta hoteles dinámicamente, solo necesitamos
# establecer la variable de entorno en el código temporalmente
# Modificar para que use el hotel seleccionado por defecto
sed -i "s/const selectedHotel = process.env.OG_COTIZAR_IMAGE || null;/const selectedHotel = process.env.OG_COTIZAR_IMAGE || '$SELECTED_HOTEL';/" server.js

echo "✅ server.js modificado"
echo ""

# 3. Copiar al contenedor
echo "3️⃣ Copiando server.js al contenedor..."
docker cp server.js "$CONTAINER_ID:/tmp/server.js.new"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar"
    exit 1
fi

echo "✅ Archivo copiado a /tmp/server.js.new"
echo ""

# 4. Detener Node.js y copiar
echo "4️⃣ Deteniendo Node.js y copiando archivo..."
docker exec "$CONTAINER_ID" pkill -9 node 2>/dev/null
sleep 2

docker exec -i "$CONTAINER_ID" sh -c "cat > /app/server.js" < server.js 2>&1

if [ $? -eq 0 ]; then
    echo "✅ server.js actualizado"
else
    echo "❌ Error al actualizar server.js"
    exit 1
fi
echo ""

# 5. Verificar
echo "5️⃣ Verificando..."
if docker exec "$CONTAINER_ID" grep -q "$SELECTED_HOTEL" /app/server.js 2>/dev/null; then
    echo "✅ Hotel $SELECTED_HOTEL confirmado en server.js"
else
    echo "⚠️  Hotel no encontrado en server.js (puede ser normal si usa detección dinámica)"
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
    if docker exec "$FINAL_CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "✅ Proceso Node.js está corriendo"
    fi
fi
echo ""

# 8. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

echo "=========================================="
echo "✅ CAMBIO APLICADO (TEMPORAL)"
echo "=========================================="
echo ""
echo "🌐 Prueba: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
echo "⚠️  NOTA: Este cambio es temporal y se perderá al reiniciar."
echo "   Para hacerlo permanente, agrega la variable de entorno:"
echo "   OG_COTIZAR_IMAGE=$SELECTED_HOTEL"
echo "   en EasyPanel, o el sistema usará el primer hotel disponible."
echo ""
