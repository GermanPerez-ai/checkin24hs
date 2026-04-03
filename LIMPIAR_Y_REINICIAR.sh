#!/bin/bash

cd /root/checkin24hs

echo "=== Limpieza completa y reinicio ==="
echo ""

# 1. Detener todos los contenedores del dashboard
echo "=== 1. Deteniendo todos los contenedores ==="
docker ps | grep dashboard | awk '{print $1}' | xargs -r docker stop
sleep 5

# 2. Eliminar todos los contenedores del dashboard
echo ""
echo "=== 2. Eliminando todos los contenedores ==="
docker ps -a | grep dashboard | awk '{print $1}' | xargs -r docker rm -f
sleep 3

# 3. Verificar que no quedan contenedores
echo ""
echo "=== 3. Verificando limpieza ==="
REMAINING=$(docker ps -a | grep dashboard | wc -l)
echo "Contenedores restantes: $REMAINING"

# 4. Reiniciar el servicio desde cero
echo ""
echo "=== 4. Reiniciando servicio ==="
docker service update --force checkin24hs_dashboard

echo "Esperando 20 segundos..."
sleep 20

# 5. Verificar estado
echo ""
echo "=== 5. Estado del servicio ==="
docker service ps checkin24hs_dashboard --no-trunc | head -5

# 6. Verificar contenedores activos
echo ""
echo "=== 6. Contenedores activos ==="
ACTIVE=$(docker ps | grep dashboard | wc -l)
echo "Contenedores activos: $ACTIVE"

if [ "$ACTIVE" -gt 1 ]; then
    echo "⚠️ Aún hay múltiples contenedores. Escalando a 1..."
    docker service scale checkin24hs_dashboard=1
    sleep 10
    docker ps | grep dashboard | awk '{print $1}' | tail -n +2 | xargs -r docker stop
fi

# 7. Verificar logs del contenedor activo
echo ""
echo "=== 7. Logs del contenedor activo ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    docker logs "$CONTAINER" --tail 10 2>&1 | tail -10
else
    echo "❌ No se encontró contenedor activo"
fi

echo ""
echo "✅ Completado"


