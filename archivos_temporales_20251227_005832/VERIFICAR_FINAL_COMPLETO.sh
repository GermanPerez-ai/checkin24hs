#!/bin/bash
cd /root/checkin24hs

echo "=== Verificación Final ==="
echo ""

echo "Líneas 5149-5153 en servidor:"
sed -n '5149,5153p' deploy/dashboard.html

echo ""
echo "Verificando contenedor activo:"
FIRST_CONTAINER=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1)
echo "Contenedor: $FIRST_CONTAINER"
echo ""
echo "Líneas 5149-5153 en contenedor:"
docker exec $FIRST_CONTAINER sed -n '5149,5153p' /app/dashboard.html 2>/dev/null

echo ""
echo "Funciones globales:"
SHOW_SECTION_LINE=$(docker exec $FIRST_CONTAINER grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
echo "showSection en línea: $SHOW_SECTION_LINE"

SEARCH_USERS_LINE=$(docker exec $FIRST_CONTAINER grep -n "window.searchUsers = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
echo "searchUsers en línea: $SEARCH_USERS_LINE"

echo ""
echo "Verificando que no haya errores de sintaxis obvios:"
if docker exec $FIRST_CONTAINER grep -q "if (!dateValue) return null" /app/dashboard.html 2>/dev/null; then
    echo "✅ Código correcto encontrado"
else
    echo "⚠️ Código no encontrado"
fi

echo ""
echo "✅ Verificación completada"




