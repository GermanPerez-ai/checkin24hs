#!/bin/bash
cd /root/checkin24hs
echo "=== DETENIENDO CONTENEDORES ==="
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Detenidos"
echo ""
echo "=== COPIANDO ARCHIVO ==="
for c in $(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do
    echo "Copiando a: $c"
    docker cp deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null || docker cp deploy/dashboard.html $c:/usr/share/nginx/html/dashboard.html 2>/dev/null
done
echo "✅ Copiado"
echo ""
echo "=== REINICIANDO CONTENEDORES ==="
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Reiniciados"
echo ""
echo "=== ESTADO ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep checkin24hs_dashboard










