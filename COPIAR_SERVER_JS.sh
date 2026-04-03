#!/bin/bash
# Encontrar y copiar server.js al contenedor

echo "=== BUSCANDO Y COPIANDO server.js ==="
echo ""

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "📦 Contenedor encontrado: $CONTAINER"
echo ""

echo "🔍 Buscando server.js en el contenedor..."
SERVER_PATH=$(docker exec "$CONTAINER" find / -name "server.js" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$SERVER_PATH" ]; then
    echo "⚠️  No se encontró server.js en el contenedor"
    echo ""
    echo "📋 Verificando estructura del contenedor..."
    docker exec "$CONTAINER" ls -la /app/ 2>/dev/null || docker exec "$CONTAINER" ls -la /usr/src/app/ 2>/dev/null || docker exec "$CONTAINER" ls -la / 2>/dev/null | head -20
else
    echo "✅ Encontrado: $SERVER_PATH"
    echo ""
    echo "📤 Copiando server.js..."
    if docker cp server.js "${CONTAINER}:${SERVER_PATH}" 2>/dev/null; then
        echo "✅ server.js copiado exitosamente"
        echo ""
        echo "🔄 Reiniciando contenedor..."
        docker restart "$CONTAINER"
        echo "✅ Contenedor reiniciado"
    else
        echo "❌ Error al copiar server.js"
    fi
fi

echo ""
echo "=== COMPLETADO ==="





