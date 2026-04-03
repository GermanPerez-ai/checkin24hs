#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO EN SERVIDOR ==="
echo "Línea 5150:"
sed -n '5150p' deploy/dashboard.html
echo ""
echo "Funciones globales en head (líneas 1557-1700):"
sed -n '1557,1700p' deploy/dashboard.html | grep -E "window\.(showSection|searchUsers|handleLogin)" | head -3
echo ""

echo "=== APLICANDO A TODOS LOS CONTENEDORES ==="
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "📦 Procesando: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container > /dev/null 2>&1
    echo "✅ $container actualizado"
done

echo ""
echo "✅ PROCESO COMPLETADO"
echo ""
echo "Ahora verifica en el navegador con Ctrl+Shift+R (hard refresh)"

