#!/bin/bash
cd /root/checkin24hs
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ] && [ -f "deploy/dashboard.html" ]; then
    LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
    CURRENT_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null || echo "0")
    if [ "$CURRENT_SIZE" != "$LOCAL_SIZE" ]; then
        docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html" 2>/dev/null
        docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || true
    fi
fi
