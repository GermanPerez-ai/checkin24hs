#!/bin/bash
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null || true
sleep 2
for container in $(docker ps -a --format "{{.Names}}" | grep checkin24hs_dashboard); do
    docker cp /root/checkin24hs/deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null
done
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null || true
echo "✅ Corrección aplicada. Espera 10-15 segundos y recarga el dashboard."
