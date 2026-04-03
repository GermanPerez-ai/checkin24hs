#!/bin/bash
cd /root/checkin24hs
echo "=== APLICANDO DASHBOARD CORREGIDO ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    echo "Deteniendo $c..."
    docker stop $c >/dev/null 2>&1
done
sleep 3
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    echo "Copiando a $c..."
    docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null && echo "✅ $c" || echo "❌ $c"
done
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    docker start $c >/dev/null 2>&1
done
sleep 5
echo "=== VERIFICACIÓN ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    fecha=$(docker exec $c ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    echo "✅ $c: $fecha"
done
echo "✅ Completado"
