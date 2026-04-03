#!/bin/bash
# Aplicar correcciones finales en el servidor

cd /root/checkin24hs

echo "=== APLICANDO CORRECCIONES FINALES ==="
echo ""

# Verificar línea 5150
echo "Línea 5150:"
sed -n '5150p' deploy/dashboard.html

echo ""
echo "Verificando funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1

echo ""
echo "Aplicando a TODOS los contenedores..."
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Procesando: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker restart $container >/dev/null 2>&1
    echo "✅ $container"
done

echo ""
echo "✅ COMPLETADO"
echo ""
echo "IMPORTANTE:"
echo "1. Abre en modo incognito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para hard refresh"
echo "3. Verifica consola (F12)"

