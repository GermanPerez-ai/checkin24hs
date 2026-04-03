#!/bin/bash
# Actualizar dashboard tanto en host como en contenedor

echo "🔄 Actualizando dashboard en ambos lugares..."
echo ""

# 1. Actualizar en host
echo "[1/3] Actualizando archivo en host..."
cd /etc/easypanel/projects/checkin24hs/dashboard/code
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# 2. Verificar Build
BUILD_NUM=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
echo "Build en host: $BUILD_NUM"

# 3. Actualizar en contenedor
echo ""
echo "[2/3] Copiando archivo al contenedor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
fi

if [ -n "$CONTAINER_ID" ]; then
    docker cp dashboard.html ${CONTAINER_ID}:/app/dashboard.html
    echo "✅ Archivo copiado al contenedor $CONTAINER_ID"
    
    # Verificar en contenedor
    CONTAINER_BUILD=$(docker exec ${CONTAINER_ID} grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html | head -1)
    echo "Build en contenedor: $CONTAINER_BUILD"
else
    echo "⚠️  Contenedor no encontrado"
fi

# 4. Reiniciar servicio
echo ""
echo "[3/3] Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

echo ""
echo "✅ Proceso completado"
echo ""
echo "Espera 10 segundos y verifica en el navegador:"
echo "  window.DASHBOARD_BUILD_NUMBER (debe ser 39)"
