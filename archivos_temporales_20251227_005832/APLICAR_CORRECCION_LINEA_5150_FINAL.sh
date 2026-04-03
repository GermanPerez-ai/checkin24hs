#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO EN SERVIDOR ==="
echo "Linea 5150:"
sed -n '5150p' deploy/dashboard.html
echo ""
echo "Funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1
echo ""

echo "=== APLICANDO A TODOS LOS CONTENEDORES ==="
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Procesando: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container
    echo "✅ $container actualizado"
    echo ""
done

echo "✅ PROCESO COMPLETADO"
echo ""
echo "INSTRUCCIONES:"
echo "1. Abre el dashboard en modo incognito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para hard refresh"
echo "3. Verifica que no haya errores en la consola"

