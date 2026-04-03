#!/bin/bash

# Script para diagnosticar y reparar el servicio CRM

set -e

SERVICE_NAME="checkin24hs_crm"

echo "=== Diagnóstico del servicio CRM ==="

# 1. Ver estado del servicio
echo ""
echo "1. Estado del servicio:"
docker service ps $SERVICE_NAME --no-trunc | head -10

# 2. Ver logs recientes
echo ""
echo "2. Últimos logs (errores):"
docker service logs $SERVICE_NAME --tail 50 | grep -i error || docker service logs $SERVICE_NAME --tail 20

# 3. Verificar que el archivo existe en el servidor
echo ""
echo "3. Verificando archivo en servidor:"
ls -lh /root/checkin24hs/serve-crm.js

# 4. Ver contenedores corriendo
echo ""
echo "4. Contenedores corriendo:"
docker ps --filter "name=$SERVICE_NAME" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

# 5. Verificar comando del servicio
echo ""
echo "5. Comando configurado en el servicio:"
docker service inspect $SERVICE_NAME --format '{{.Spec.TaskTemplate.ContainerSpec.Command}}' 2>/dev/null || echo "No se pudo obtener el comando"

# 6. Intentar copiar a contenedores corriendo
echo ""
echo "6. Copiando archivo a contenedores corriendo:"
RUNNING_CONTAINERS=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}")
if [ ! -z "$RUNNING_CONTAINERS" ]; then
    for CONTAINER_ID in $RUNNING_CONTAINERS; do
        echo "Copiando a contenedor $CONTAINER_ID..."
        docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1
        echo "Verificando archivo:"
        docker exec $CONTAINER_ID ls -lh /app/serve-crm.js 2>&1 | head -1 || echo "  ERROR: No se encontró el archivo"
        echo "Verificando proceso:"
        docker exec $CONTAINER_ID ps aux | grep node | head -3 || echo "  No hay proceso node corriendo"
    done
else
    echo "No hay contenedores corriendo"
fi

# 7. Verificar si el servicio está pausado
echo ""
echo "7. Estado del servicio (pausado?):"
docker service inspect $SERVICE_NAME --format '{{.UpdateStatus.State}}' 2>/dev/null || echo "No se pudo obtener el estado"

echo ""
echo "=== Diagnóstico completado ==="

