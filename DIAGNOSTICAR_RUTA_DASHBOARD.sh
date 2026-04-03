#!/bin/bash
# Script para diagnosticar dónde está realmente el dashboard.html

echo "=========================================="
echo "DIAGNÓSTICO DE RUTA DEL DASHBOARD"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_NAME=$(docker service ps ${SERVICE_NAME} --format "{{.Name}}" --filter "desired-state=running" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: ${CONTAINER_NAME}"
echo ""

echo "🔍 1. Buscando dashboard.html en el contenedor..."
echo ""
docker exec ${CONTAINER_NAME} find / -name "dashboard.html" -type f 2>/dev/null | head -5
echo ""

echo "🔍 2. Verificando ruta /usr/share/nginx/html/..."
echo ""
docker exec ${CONTAINER_NAME} ls -lah /usr/share/nginx/html/ 2>/dev/null | head -10
echo ""

echo "🔍 3. Verificando si es un contenedor Node.js..."
echo ""
docker exec ${CONTAINER_NAME} ls -lah /app/ 2>/dev/null | head -10
echo ""

echo "🔍 4. Buscando proceso principal..."
echo ""
docker exec ${CONTAINER_NAME} ps aux | grep -E "nginx|node" | head -5
echo ""

echo "🔍 5. Verificando puerto 80..."
echo ""
docker exec ${CONTAINER_NAME} netstat -tlnp 2>/dev/null | grep -E ":80|:3000" || docker exec ${CONTAINER_NAME} ss -tlnp 2>/dev/null | grep -E ":80|:3000"
echo ""
