#!/bin/bash

echo "=========================================="
echo "Forzar uso de serve-dashboard.js"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar que serve-dashboard.js existe localmente
if [ ! -f "serve-dashboard.js" ]; then
    echo "❌ Error: serve-dashboard.js no existe en /root/checkin24hs"
    exit 1
fi

echo "✅ serve-dashboard.js encontrado localmente"
echo ""

# 2. Obtener contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor corriendo"
    exit 1
fi

echo "Contenedor actual: $CONTAINER_ID"
echo ""

# 3. Copiar serve-dashboard.js al contenedor
echo "=== Copiando serve-dashboard.js ==="
docker cp serve-dashboard.js $CONTAINER_ID:/app/serve-dashboard.js
echo "✅ Archivo copiado"
echo ""

# 4. Verificar que se copió
docker exec $CONTAINER_ID ls -lh /app/serve-dashboard.js
echo ""

# 5. Matar el proceso actual y ejecutar serve-dashboard.js manualmente
echo "=== Deteniendo server.js y ejecutando serve-dashboard.js ==="
docker exec -d $CONTAINER_ID sh -c "pkill -f 'node server.js' && sleep 2 && node /app/serve-dashboard.js > /tmp/serve-dashboard.log 2>&1 &"
sleep 3

# 6. Verificar que serve-dashboard.js está corriendo
echo "=== Verificando proceso ==="
docker exec $CONTAINER_ID ps aux | grep node
echo ""

# 7. Probar acceso
echo "=== Probando acceso ==="
docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -5
echo ""

# 8. Ver logs de serve-dashboard.js
echo "=== Ver logs de serve-dashboard.js ==="
docker exec $CONTAINER_ID cat /tmp/serve-dashboard.log 2>&1 | tail -10
echo ""

# 9. Si funciona, actualizar el servicio para que use serve-dashboard.js permanentemente
echo "=== Actualizar servicio permanentemente ==="
echo "Intentando actualizar el servicio para usar serve-dashboard.js..."

# Obtener la configuración actual del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.ContainerSpec}}' > /tmp/service_config.json 2>&1

# Actualizar el servicio con el comando correcto
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
    echo "Solución alternativa: Necesitas actualizar la configuración en EasyPanel:"
    echo "1. Ve a EasyPanel"
    echo "2. Abre el servicio checkin24hs_dashboard"
    echo "3. Ve a la configuración y cambia el comando de inicio a: node serve-dashboard.js"
    echo "4. Guarda y haz redeploy"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""




