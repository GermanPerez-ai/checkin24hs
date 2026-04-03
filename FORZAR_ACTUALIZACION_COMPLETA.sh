#!/bin/bash
# Forzar actualización completa del dashboard

echo "🔄 FORZANDO ACTUALIZACIÓN COMPLETA..."
echo ""

# 1. Descargar archivo
echo "[1/5] Descargando Build #39 desde GitHub..."
cd /etc/easypanel/projects/checkin24hs/dashboard/code
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Verificar Build en host
BUILD_HOST=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
echo "Build en archivo descargado: $BUILD_HOST"

# 2. Encontrar contenedor
echo ""
echo "[2/5] Buscando contenedor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"

# 3. Verificar ruta del archivo en el contenedor
echo ""
echo "[3/5] Verificando ruta del archivo en contenedor..."
docker exec ${CONTAINER_ID} ls -la /app/dashboard.html 2>/dev/null || docker exec ${CONTAINER_ID} find / -name "dashboard.html" -type f 2>/dev/null | head -1

# 4. Copiar archivo al contenedor
echo ""
echo "[4/5] Copiando archivo al contenedor..."
docker cp dashboard.html ${CONTAINER_ID}:/app/dashboard.html

# Verificar Build en contenedor
CONTAINER_BUILD=$(docker exec ${CONTAINER_ID} grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1)
echo "Build en contenedor después de copiar: $CONTAINER_BUILD"

# 5. Reiniciar contenedor directamente (más agresivo)
echo ""
echo "[5/5] Reiniciando contenedor..."
docker restart ${CONTAINER_ID}

echo ""
echo "⏳ Esperando 10 segundos..."
sleep 10

# 6. Reiniciar servicio también
echo ""
echo "🔄 Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

echo ""
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Verificaciones:"
echo "  - Build en host: $BUILD_HOST"
echo "  - Build en contenedor: $CONTAINER_BUILD"
echo ""
echo "🔄 Limpia caché del navegador y recarga con Ctrl+Shift+R"
echo "  Luego verifica: window.DASHBOARD_BUILD_NUMBER"
