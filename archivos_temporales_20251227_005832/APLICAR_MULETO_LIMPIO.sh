#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO ==="
echo "Tamaño del archivo:"
ls -lh deploy/dashboard.html
echo ""
echo "Funciones globales en head:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1
grep -n "window.handleLogin = function" deploy/dashboard.html | head -1
echo ""

echo "=== APLICANDO A TODOS LOS CONTENEDORES ==="
CONTAINERS=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard")
COUNT=$(echo "$CONTAINERS" | wc -l)
echo "Contenedores encontrados: $COUNT"
echo ""

for container in $CONTAINERS; do
    echo "📦 Procesando: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    if [ $? -eq 0 ]; then
        echo "  ✅ Archivo copiado"
        docker restart $container > /dev/null 2>&1
        echo "  ✅ Contenedor reiniciado"
    else
        echo "  ❌ Error copiando archivo"
    fi
    echo ""
done

echo "✅ PROCESO COMPLETADO"
echo ""
echo "INSTRUCCIONES:"
echo "1. Abre el dashboard en modo incognito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para hard refresh"
echo "3. Verifica que no haya errores en la consola"

