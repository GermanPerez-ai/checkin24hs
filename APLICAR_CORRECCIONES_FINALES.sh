#!/bin/bash
# Aplicar correcciones finales - eliminar todas las líneas que dan error

cd /root/checkin24hs

echo "=== APLICANDO CORRECCIONES FINALES ==="
echo ""

# Verificar funciones globales
echo "Verificando funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1

echo ""
echo "Verificando línea 5261 (expensesCharts):"
sed -n '5261p' deploy/dashboard.html

echo ""
echo "Aplicando a todos los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Copiando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    # Verificar
    LINE_5261=$(docker exec $container sed -n '5261p' /app/dashboard.html 2>/dev/null)
    echo "  Línea 5261: $LINE_5261"
    
    docker restart $container 2>/dev/null
    echo "  Reiniciado"
    echo ""
done

echo "=== COMPLETADO ==="
echo ""
echo "Abre en modo incognito: https://dashboard.checkin24hs.com/"
echo "Verifica que no haya errores en la consola (F12)"
