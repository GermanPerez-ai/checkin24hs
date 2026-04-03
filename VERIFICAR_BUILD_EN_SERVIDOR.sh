#!/bin/bash
# Verificar Build en servidor

echo "🔍 Verificando Build Number en servidor..."
echo ""

# 1. Verificar archivo en host
echo "[1/3] Verificando archivo en host..."
cd /etc/easypanel/projects/checkin24hs/dashboard/code
if [ -f "dashboard.html" ]; then
    BUILD_HOST=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1)
    echo "✅ Build en archivo host: $BUILD_HOST"
    ls -lh dashboard.html | head -1
else
    echo "❌ Archivo dashboard.html no encontrado"
fi

# 2. Encontrar contenedor
echo ""
echo "[2/3] Buscando contenedor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"

# 3. Verificar Build en contenedor
echo ""
echo "[3/3] Verificando Build en contenedor..."
CONTAINER_BUILD=$(docker exec ${CONTAINER_ID} grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1)

if [ -z "$CONTAINER_BUILD" ]; then
    echo "⚠️  No se pudo leer Build del contenedor"
    echo "Buscando archivo en otras rutas..."
    docker exec ${CONTAINER_ID} find / -name "dashboard.html" -type f 2>/dev/null | head -3
else
    echo "✅ Build en contenedor: $CONTAINER_BUILD"
fi

# 4. Resumen
echo ""
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Build en host:   $BUILD_HOST"
echo "Build en contenedor: $CONTAINER_BUILD"
echo ""

if [ "$BUILD_HOST" = "39" ] && [ "$CONTAINER_BUILD" != "39" ]; then
    echo "⚠️  PROBLEMA: El host tiene Build #39 pero el contenedor tiene #$CONTAINER_BUILD"
    echo "   Ejecuta: docker cp dashboard.html ${CONTAINER_ID}:/app/dashboard.html"
    echo "   Luego: docker restart ${CONTAINER_ID}"
elif [ "$BUILD_HOST" != "39" ]; then
    echo "⚠️  PROBLEMA: El archivo en host no tiene Build #39"
    echo "   Ejecuta: curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"
else
    echo "✅ Todo parece correcto en el servidor"
    echo "   El problema puede ser caché del navegador"
fi
