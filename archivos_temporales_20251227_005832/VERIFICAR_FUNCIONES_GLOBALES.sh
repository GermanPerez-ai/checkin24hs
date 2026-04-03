#!/bin/bash
# Script para verificar que las funciones globales estén en el archivo

FIRST_CONTAINER=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontraron contenedores"
    exit 1
fi

echo "🔍 Verificando funciones globales en contenedor: $FIRST_CONTAINER"
echo ""

# Verificar showSection
echo "📋 Buscando window.showSection:"
docker exec $FIRST_CONTAINER grep -n "window.showSection = function" /app/dashboard.html | head -3

# Verificar searchUsers
echo ""
echo "📋 Buscando window.searchUsers:"
docker exec $FIRST_CONTAINER grep -n "window.searchUsers = function" /app/dashboard.html | head -3

# Verificar que estén al inicio (antes de </head>)
echo ""
echo "📋 Verificando que estén antes de </head>:"
docker exec $FIRST_CONTAINER grep -n "</head>" /app/dashboard.html | head -1
HEAD_LINE=$(docker exec $FIRST_CONTAINER grep -n "</head>" /app/dashboard.html | head -1 | cut -d: -f1)
echo "   Línea de </head>: $HEAD_LINE"

SHOW_SECTION_LINE=$(docker exec $FIRST_CONTAINER grep -n "window.showSection = function" /app/dashboard.html | head -1 | cut -d: -f1)
if [ ! -z "$SHOW_SECTION_LINE" ] && [ "$SHOW_SECTION_LINE" -lt "$HEAD_LINE" ]; then
    echo "   ✅ showSection está antes de </head> (línea $SHOW_SECTION_LINE)"
else
    echo "   ❌ showSection NO está antes de </head>"
fi

SEARCH_USERS_LINE=$(docker exec $FIRST_CONTAINER grep -n "window.searchUsers = function" /app/dashboard.html | head -1 | cut -d: -f1)
if [ ! -z "$SEARCH_USERS_LINE" ] && [ "$SEARCH_USERS_LINE" -lt "$HEAD_LINE" ]; then
    echo "   ✅ searchUsers está antes de </head> (línea $SEARCH_USERS_LINE)"
else
    echo "   ❌ searchUsers NO está antes de </head>"
fi

echo ""
echo "✅ Verificación completada"




