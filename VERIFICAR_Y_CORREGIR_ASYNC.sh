#!/bin/bash

cd /root/checkin24hs

echo "=== VERIFICANDO FUNCIÓN ASYNC EN CONTENEDOR ==="
CONTAINER=$(docker ps --format '{{.Names}}' | grep checkin24hs_dashboard | head -1)
echo "Contenedor: $CONTAINER"
echo ""

echo "Línea 9005 (debe ser 'async function showWhatsAppConfig'):"
docker exec $CONTAINER sed -n '9005p' /app/dashboard.html
echo ""

echo "Línea 9018 (debe tener 'await loadWhatsAppConfig()'):"
docker exec $CONTAINER sed -n '9018p' /app/dashboard.html
echo ""

echo "Verificando si la función es async:"
docker exec $CONTAINER grep -n 'async function showWhatsAppConfig' /app/dashboard.html
echo ""

echo "=== SI LA FUNCIÓN NO ES ASYNC, APLICAR CORRECCIÓN ==="
echo "Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard")
sleep 2

echo "Copiando archivo corregido..."
for c in $(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do
    docker cp deploy/dashboard.html $c:/app/dashboard.html
    echo "✅ Copiado a $c"
done

echo "Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard")

echo ""
echo "✅ Proceso completado"
echo "⚠️ IMPORTANTE: Limpia la caché del navegador (Ctrl+Shift+Delete) y haz hard refresh (Ctrl+Shift+R)"









