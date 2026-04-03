#!/bin/bash
# Script para aplicar server.js durante el reinicio del servicio

echo "=========================================="
echo "🔧 APLICANDO SERVER.JS (DURANTE REINICIO)"
echo "=========================================="
echo ""

# 1. Descargar server.js desde GitHub primero
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

# 2. Verificar que tiene la ruta
if ! grep -q "og-cotizar.jpg" checkin24hs/checkin24hs-admin/server.js; then
    echo "❌ server.js no tiene la ruta /og-cotizar.jpg"
    exit 1
fi

echo "✅ Ruta /og-cotizar.jpg encontrada"
echo ""

# 3. Buscar servicio
SERVICE_NAME="checkin24hs_dashboard"
echo "2️⃣ Buscando servicio: $SERVICE_NAME"
echo ""

# 4. Iniciar reinicio del servicio en background y copiar durante el reinicio
echo "3️⃣ Reiniciando servicio y copiando archivo durante el reinicio..."
docker service update --force "$SERVICE_NAME" &

# Esperar un momento para que el contenedor comience a reiniciarse
sleep 5

# Intentar copiar el archivo múltiples veces durante el reinicio
MAX_ATTEMPTS=10
ATTEMPT=0
SUCCESS=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "   Intento $ATTEMPT/$MAX_ATTEMPTS..."
    
    # Buscar cualquier contenedor del servicio (puede estar reiniciándose)
    CONTAINER_ID=$(docker ps -a --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER_ID" ]; then
        # Intentar copiar el archivo
        if docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/app/server.js" 2>/dev/null; then
            echo "   ✅ server.js copiado exitosamente"
            SUCCESS=1
            break
        fi
    fi
    
    sleep 2
done

if [ $SUCCESS -eq 0 ]; then
    echo "   ⚠️  No se pudo copiar durante el reinicio"
    echo "   Esperando a que el servicio se estabilice..."
    sleep 20
    
    # Intentar una vez más cuando el servicio esté estable
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "   Intentando copiar ahora..."
        # Detener Node.js temporalmente
        docker exec "$CONTAINER_ID" pkill -9 -f "node.*server.js" 2>/dev/null
        sleep 1
        if docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/app/server.js" 2>/dev/null; then
            echo "   ✅ server.js copiado"
            SUCCESS=1
            # Reiniciar Node.js
            docker service update --force "$SERVICE_NAME" > /dev/null 2>&1
        fi
    fi
fi

echo ""

# 5. Esperar a que el servicio se estabilice
echo "4️⃣ Esperando a que el servicio se estabilice..."
sleep 30

# 6. Verificar
echo "5️⃣ Verificando..."
FINAL_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$FINAL_CONTAINER" ]; then
    if docker exec "$FINAL_CONTAINER" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
        echo "   ✅ Ruta /og-cotizar.jpg encontrada en el contenedor"
        SUCCESS=1
    else
        echo "   ⚠️  Ruta no encontrada"
    fi
    
    if docker exec "$FINAL_CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Proceso Node.js está corriendo"
    else
        echo "   ⚠️  Proceso Node.js no está corriendo"
    fi
else
    echo "   ⚠️  No se encontró contenedor"
fi
echo ""

# 7. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

if [ $SUCCESS -eq 1 ]; then
    echo "=========================================="
    echo "✅ SERVER.JS APLICADO"
    echo "=========================================="
    echo ""
    echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com/og-cotizar.jpg"
    echo ""
else
    echo "=========================================="
    echo "⚠️  NO SE PUDO APLICAR COMPLETAMENTE"
    echo "=========================================="
    echo ""
    echo "El archivo puede estar montado como volumen."
    echo "Para hacer el cambio permanente, actualiza el Dockerfile y haz rebuild desde EasyPanel."
    echo ""
fi
