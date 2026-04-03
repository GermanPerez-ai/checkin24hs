#!/bin/bash
cd /root/checkin24hs
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    line=$(docker exec $c sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if ! echo "$line" | grep -q "editHotelName"; then
        echo "Corrigiendo $c..."
        docker stop $c >/dev/null 2>&1
        sleep 1
        docker cp deploy/dashboard.html $c:/app/dashboard.html
        docker start $c >/dev/null 2>&1
        sleep 2
        echo "✅ $c corregido"
    fi
done
