#!/bin/bash
# Script para verificar que el archivo copiado tiene las correcciones

FIRST_CONTAINER=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontraron contenedores"
    exit 1
fi

echo "🔍 Verificando archivo en contenedor: $FIRST_CONTAINER"
echo ""

# Verificar línea 5150 (debería tener "var date = null;")
echo "📋 Verificando línea 5150 (debería tener 'var date = null;'):"
docker exec $FIRST_CONTAINER sed -n '5150p' /app/dashboard.html

echo ""
echo "📋 Verificando función normalizeDate (debería ser 'function' no arrow):"
docker exec $FIRST_CONTAINER sed -n '5146p' /app/dashboard.html

echo ""
echo "📋 Verificando funciones globales al inicio (debería tener showSection y searchUsers):"
docker exec $FIRST_CONTAINER grep -n "window.showSection = function" /app/dashboard.html | head -1
docker exec $FIRST_CONTAINER grep -n "window.searchUsers = function" /app/dashboard.html | head -1

echo ""
echo "✅ Verificación completada"




