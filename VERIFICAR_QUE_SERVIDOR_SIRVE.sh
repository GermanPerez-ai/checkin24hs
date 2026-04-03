#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR QUÉ ESTÁ SIRVIENDO EL SERVIDOR"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar server.js - qué archivo está usando
echo "=== 1. VERIFICAR server.js ==="
SERVER_PATH=$(docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -1)
if [ -n "$SERVER_PATH" ]; then
    echo "✅ server.js encontrado: $SERVER_PATH"
    echo ""
    echo "Buscando referencias a dashboard.html:"
    docker exec "$CONTAINER" grep -n "dashboard.html" "$SERVER_PATH" 2>/dev/null | head -10
else
    echo "❌ No se encontró server.js"
fi
echo ""

# 2. Hacer curl directo al servidor (desde dentro del contenedor)
echo "=== 2. HACER CURL DESDE EL SERVIDOR ==="
echo "Obteniendo dashboard.html directamente desde el servidor..."
docker exec "$CONTAINER" curl -s http://localhost:3000 2>/dev/null | grep -A 12 'class="header"' | head -13
echo ""

# 3. Verificar qué proceso está corriendo
echo "=== 3. PROCESO DEL SERVICIO ==="
docker exec "$CONTAINER" ps aux | grep -E "node|npm"
echo ""

# 4. Verificar directorio de trabajo
echo "=== 4. DIRECTORIO DE TRABAJO ==="
docker exec "$CONTAINER" pwd
echo ""

# 5. Verificar archivos en el directorio de trabajo
echo "=== 5. ARCHIVOS EN EL DIRECTORIO ==="
SERVER_DIR=$(dirname "$SERVER_PATH" 2>/dev/null || echo "/app")
docker exec "$CONTAINER" ls -lah "$SERVER_DIR" 2>/dev/null | grep -E "dashboard|server" | head -10
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
