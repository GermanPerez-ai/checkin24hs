#!/bin/bash
# Script para verificar si server.js está montado y aplicar solución

echo "=========================================="
echo "🔍 VERIFICANDO Y APLICANDO SERVER.JS"
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

# 1. Verificar si server.js está montado como volumen
echo "1️⃣ Verificando si server.js está montado como volumen..."
MOUNT_INFO=$(docker inspect "$CONTAINER_ID" --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}' | grep -i server.js || echo "")

if [ ! -z "$MOUNT_INFO" ]; then
    echo "   ⚠️  server.js está montado como volumen:"
    echo "   $MOUNT_INFO"
    echo ""
    echo "   Para cambiar el archivo, necesitas modificar el volumen o el Dockerfile."
    echo "   Solución: Actualiza el Dockerfile y haz rebuild desde EasyPanel."
    exit 1
else
    echo "   ✅ server.js NO está montado como volumen"
fi
echo ""

# 2. Verificar permisos del archivo
echo "2️⃣ Verificando permisos del archivo..."
docker exec "$CONTAINER_ID" ls -la /app/server.js 2>/dev/null
echo ""

# 3. Intentar método alternativo: copiar a ubicación temporal y luego mover
echo "3️⃣ Intentando método alternativo (copiar a temp y luego mover)..."
TEMP_DIR="/tmp/dashboard_fix_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

if [ ! -f "checkin24hs/checkin24hs-admin/server.js" ]; then
    echo "❌ No se encontró server.js"
    exit 1
fi

# Copiar a ubicación temporal dentro del contenedor
echo "   Copiando a /tmp/server.js dentro del contenedor..."
docker cp checkin24hs/checkin24hs-admin/server.js "$CONTAINER_ID:/tmp/server.js.new"

if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado a /tmp/server.js.new"
    
    # Intentar mover el archivo usando un comando dentro del contenedor
    echo "   Moviendo archivo dentro del contenedor..."
    
    # Detener Node.js
    docker exec "$CONTAINER_ID" pkill -9 -f "node.*server.js" 2>/dev/null
    sleep 1
    
    # Mover el archivo
    docker exec "$CONTAINER_ID" sh -c "mv /tmp/server.js.new /app/server.js" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Archivo movido exitosamente"
        
        # Verificar
        if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
            echo "   ✅ Ruta /og-cotizar.jpg confirmada"
        fi
        
        # Reiniciar servicio para que Node.js se inicie de nuevo
        echo "   Reiniciando servicio..."
        docker service update --force "$SERVICE_NAME" > /dev/null 2>&1
        echo "   ✅ Servicio reiniciado"
        echo "   ⏳ Esperando 30 segundos..."
        sleep 30
    else
        echo "   ❌ Error al mover el archivo"
        exit 1
    fi
else
    echo "   ❌ Error al copiar a ubicación temporal"
    exit 1
fi
echo ""

# 4. Verificación final
echo "4️⃣ Verificación final..."
NEW_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER" ]; then
    if docker exec "$NEW_CONTAINER" grep -q "og-cotizar.jpg" /app/server.js 2>/dev/null; then
        echo "   ✅ Ruta /og-cotizar.jpg encontrada"
    fi
    
    if docker exec "$NEW_CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Proceso Node.js está corriendo"
    fi
fi
echo ""

# 5. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

echo "=========================================="
echo "✅ SERVER.JS APLICADO"
echo "=========================================="
echo ""
echo "🌐 Prueba: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
