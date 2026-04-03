#!/bin/bash
# Aplicar backup corregido - dashboard.html con funciones globales

cd /root/checkin24hs

echo "=== APLICANDO BACKUP CORREGIDO ==="
echo ""

# Verificar línea 5150
echo "Verificando línea 5150:"
sed -n '5150p' deploy/dashboard.html

echo ""
echo "Verificando funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1

echo ""
echo "Aplicando a todos los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "Copiando a $container..."
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
    
    # Verificar
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    echo "  Línea 5150: $LINE_5150"
    
    docker restart $container 2>/dev/null
    echo "  Reiniciado"
    echo ""
done

echo "=== COMPLETADO ==="
echo ""
echo "Abre en modo incognito: https://dashboard.checkin24hs.com/"

