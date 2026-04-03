#!/bin/bash
# Script para verificar el archivo completo alrededor de la línea 5150

FIRST_CONTAINER=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontraron contenedores"
    exit 1
fi

echo "🔍 Verificando archivo en contenedor: $FIRST_CONTAINER"
echo ""

# Verificar líneas alrededor de 5150
echo "📋 Líneas 5145-5155 en el contenedor:"
docker exec $FIRST_CONTAINER sed -n '5145,5155p' /app/dashboard.html

echo ""
echo "📋 Buscando 'var date = null' en el archivo:"
docker exec $FIRST_CONTAINER grep -n "var date = null" /app/dashboard.html | head -3

echo ""
echo "📋 Buscando 'const normalizeDate = function' en el archivo:"
docker exec $FIRST_CONTAINER grep -n "const normalizeDate = function" /app/dashboard.html | head -3

echo ""
echo "📋 Verificando funciones globales al inicio:"
docker exec $FIRST_CONTAINER grep -n "window.showSection = function" /app/dashboard.html | head -1
docker exec $FIRST_CONTAINER grep -n "window.searchUsers = function" /app/dashboard.html | head -1

echo ""
echo "✅ Verificación completada"




