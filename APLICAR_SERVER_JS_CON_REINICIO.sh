#!/bin/bash
# Script para aplicar server.js deteniendo el proceso primero

echo "=========================================="
echo "🔧 APLICANDO SERVER.JS (CON REINICIO)"
echo "=========================================="
echo ""

# 1. Buscar contenedor
SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 2. Descargar server.js desde GitHub
echo "2️⃣ Descargando server.js desde GitHub..."
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

# 3. Verificar que tiene la ruta
if ! grep -q "og-cotizar.jpg" checkin24hs/checkin24hs-admin/server.js; then
    echo "❌ server.js no tiene la ruta /og-cotizar.jpg"
    exit 1
fi

echo "✅ Ruta /og-cotizar.jpg encontrada"
echo ""

# 4. Detener el proceso Node.js
echo "4️⃣ Deteniendo proceso Node.js..."
docker exec "$CONTAINER_ID" pkill -9 -f "node.*server.js" 2>/dev/null
sleep 2

# Verificar que se detuvo
if docker exec "$CONTAINER_ID" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ⚠️  Proceso aún corriendo, intentando otra vez..."
    docker exec "$CONTAINER_ID" killall -9 node 2>/dev/null
    sleep 2
fi

echo "   ✅ Proceso detenido"
echo ""

# 5. Copiar server.js al contenedor
echo "5️⃣ Copiando server.js al contenedor..."
docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/app/server.js"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar server.js"
    exit 1
fi

echo "✅ server.js copiado exitosamente"
echo ""

# 6. Verificar que se copió
echo "6️⃣ Verificando que se copió correctamente..."
if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
    echo "   ✅ Ruta /og-cotizar.jpg encontrada en el contenedor"
else
    echo "   ⚠️  Ruta no encontrada"
fi
echo ""

# 7. Reiniciar el servicio completo (esto iniciará el proceso Node.js de nuevo)
echo "7️⃣ Reiniciando servicio para iniciar Node.js..."
docker service update --force "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Servicio reiniciado"
    echo "   ⏳ Esperando 30 segundos para que el servicio se inicie..."
    sleep 30
else
    echo "   ❌ Error al reiniciar el servicio"
    exit 1
fi
echo ""

# 8. Verificar que el proceso está corriendo
echo "8️⃣ Verificando que el proceso está corriendo..."
NEW_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER" ]; then
    if docker exec "$NEW_CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Proceso Node.js está corriendo"
        
        # Verificar que tiene la ruta
        if docker exec "$NEW_CONTAINER" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
            echo "   ✅ Ruta /og-cotizar.jpg confirmada en el contenedor"
        fi
    else
        echo "   ⚠️  Proceso Node.js no está corriendo"
    fi
else
    echo "   ⚠️  No se encontró nuevo contenedor"
fi
echo ""

# 9. Limpiar
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
echo "   Se perderá al reiniciar el servicio desde EasyPanel."
echo "   Para hacerlo permanente, asegúrate de que server.js esté en GitHub"
echo "   y haz rebuild desde EasyPanel."
echo ""
