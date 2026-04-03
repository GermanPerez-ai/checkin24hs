#!/bin/bash
# INSTALACION LIMPIA desde muleto.html

cd /root/checkin24hs

echo "=== INSTALACION LIMPIA ==="
echo ""

# Backup del archivo actual
if [ -f "deploy/dashboard.html" ]; then
    cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup creado"
fi

# Verificar que el archivo existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ ERROR: No se encuentra deploy/dashboard.html"
    echo "Sube el archivo primero con: scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/"
    exit 1
fi

# Verificar línea 5150
echo "Verificando línea 5150:"
sed -n '5150p' deploy/dashboard.html

echo ""
echo "Verificando funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1

echo ""
echo "Aplicando a TODOS los contenedores..."
COUNT=0
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    COUNT=$((COUNT + 1))
    echo "[$COUNT] $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    docker restart $container >/dev/null 2>&1
    echo "  ✅ Actualizado"
done

echo ""
echo "=== COMPLETADO ==="
echo "Contenedores actualizados: $COUNT"
echo ""
echo "VERIFICA en modo incognito (Ctrl+Shift+N) y presiona Ctrl+Shift+R"

