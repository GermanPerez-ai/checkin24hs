#!/bin/bash
cd /root/checkin24hs
echo "=== APLICANDO DASHBOARD CON RESET DE ESTADOS ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker stop
sleep 3
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html && echo "✅ $c" || echo "❌ $c"
done
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker start
sleep 5
echo "=== VERIFICACIÓN ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    fecha=$(docker exec $c ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    echo "✅ $c: $fecha"
done
echo "✅ Completado - Recarga el dashboard con Ctrl+Shift+R"
