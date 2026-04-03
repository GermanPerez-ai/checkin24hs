#!/bin/bash
# Aplicar directamente en el servidor SIN depender de EasyPanel

cd /root/checkin24hs

echo "=== APLICAR DIRECTO EN SERVIDOR ==="
echo ""

# Verificar que el archivo existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ ERROR: No se encuentra deploy/dashboard.html"
    echo "Sube el archivo primero con:"
    echo "scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

# Backup
cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"

# Verificar línea 5150
echo ""
echo "Línea 5150:"
sed -n '5150p' deploy/dashboard.html

# Verificar funciones globales
echo ""
echo "Funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1

echo ""
echo "Aplicando a TODOS los contenedores..."
COUNT=0
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    COUNT=$((COUNT + 1))
    echo "[$COUNT] $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    if [ $? -eq 0 ]; then
        docker restart $container >/dev/null 2>&1
        echo "  ✅ Actualizado y reiniciado"
    else
        echo "  ❌ Error copiando"
    fi
done

echo ""
echo "=== COMPLETADO ==="
echo "Contenedores actualizados: $COUNT"
echo ""
echo "VERIFICA en modo incognito (Ctrl+Shift+N) y presiona Ctrl+Shift+R"

