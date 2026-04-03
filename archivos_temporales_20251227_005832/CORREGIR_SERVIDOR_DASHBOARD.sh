#!/bin/bash

echo "=========================================="
echo "Corregir Servidor Dashboard"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 2. Verificar qué archivo está ejecutando
echo "=== Verificar proceso actual ==="
docker exec $CONTAINER_ID ps aux | grep node
echo ""

# 3. Verificar archivos disponibles
echo "=== Verificar archivos en /app ==="
docker exec $CONTAINER_ID ls -lh /app/*.js 2>&1
echo ""

# 4. Verificar si serve-dashboard.js existe
echo "=== Verificar serve-dashboard.js ==="
docker exec $CONTAINER_ID test -f /app/serve-dashboard.js && echo "✅ serve-dashboard.js existe" || echo "❌ serve-dashboard.js NO existe"
echo ""

# 5. Verificar si server.js existe
echo "=== Verificar server.js ==="
docker exec $CONTAINER_ID test -f /app/server.js && echo "✅ server.js existe" || echo "❌ server.js NO existe"
echo ""

# 6. Si serve-dashboard.js existe, copiarlo desde el servidor local
if [ -f "serve-dashboard.js" ]; then
    echo "=== Copiar serve-dashboard.js al contenedor ==="
    docker cp serve-dashboard.js $CONTAINER_ID:/app/serve-dashboard.js
    echo "✅ Archivo copiado"
    echo ""
fi

# 7. Verificar dashboard.html
echo "=== Verificar dashboard.html ==="
docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>&1
echo ""

# 8. El problema es que el CMD del Dockerfile puede estar siendo sobrescrito
# Necesitamos verificar la configuración del servicio
echo "=== Verificar configuración del servicio ==="
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Command}}' 2>&1
echo ""

# 9. Actualizar el servicio para usar serve-dashboard.js explícitamente
echo "=== Actualizar servicio para usar serve-dashboard.js ==="
docker service update \
  --args "node serve-dashboard.js" \
  checkin24hs_dashboard 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado"
    echo ""
    echo "Esperando 30 segundos para que se recree el contenedor..."
    sleep 30
    
    NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
    if [ ! -z "$NEW_CONTAINER_ID" ]; then
        echo "Nuevo contenedor: $NEW_CONTAINER_ID"
        echo ""
        echo "Verificando proceso:"
        docker exec $NEW_CONTAINER_ID ps aux | grep node
        echo ""
        echo "Probando acceso:"
        docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -5
    fi
else
    echo "⚠️  No se pudo actualizar el servicio directamente"
    echo ""
    echo "Solución alternativa: Copiar serve-dashboard.js y reiniciar manualmente"
    if [ -f "serve-dashboard.js" ]; then
        docker cp serve-dashboard.js $CONTAINER_ID:/app/serve-dashboard.js
        echo "✅ Archivo copiado"
        echo "Ahora necesitas reiniciar el contenedor manualmente o cambiar el CMD"
    fi
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""




