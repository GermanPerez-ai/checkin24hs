#!/bin/bash
# Verificar el contenido de server.js en el contenedor

echo "=========================================="
echo "🔍 Verificando server.js en el contenedor"
echo "=========================================="
echo ""

DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

echo "1️⃣ Verificando si server.js existe..."
docker exec "$DASHBOARD_CONTAINER" test -f /app/server.js && echo "✅ server.js existe" || echo "❌ server.js NO existe"

echo ""
echo "2️⃣ Verificando las primeras 60 líneas de server.js..."
docker exec "$DASHBOARD_CONTAINER" head -60 /app/server.js

echo ""
echo "3️⃣ Buscando el endpoint /api/version..."
docker exec "$DASHBOARD_CONTAINER" grep -n "/api/version" /app/server.js

echo ""
echo "4️⃣ Verificando contexto alrededor de /api/version (10 líneas antes y después)..."
docker exec "$DASHBOARD_CONTAINER" grep -A 10 -B 5 "/api/version" /app/server.js

echo ""
echo "5️⃣ Verificando si el servidor está escuchando..."
docker exec "$DASHBOARD_CONTAINER" netstat -tuln | grep 3000 || docker exec "$DASHBOARD_CONTAINER" ss -tuln | grep 3000

echo ""
echo "6️⃣ Probando acceso al endpoint directamente..."
docker exec "$DASHBOARD_CONTAINER" curl -s http://localhost:3000/api/version || echo "❌ Error al acceder al endpoint"

echo ""
echo "7️⃣ Verificando logs del servidor para errores..."
docker logs "$DASHBOARD_CONTAINER" --tail 50 | grep -iE "error|version|api" | tail -10

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
