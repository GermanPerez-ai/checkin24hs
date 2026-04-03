#!/bin/bash
echo "Restaurando desde estado1..."
cp /root/checkin24hs/backups/estado1/dashboard.html /root/checkin24hs/dashboard.html
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
docker cp /root/checkin24hs/dashboard.html ${CONTAINER_ID}:/app/dashboard.html
docker service update --force checkin24hs_dashboard
sleep 30
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
docker cp /root/checkin24hs/dashboard.html ${NEW_CONTAINER_ID}:/app/dashboard.html
echo "Restauracion completada. Recarga con Ctrl+F5"
