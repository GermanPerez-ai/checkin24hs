#!/bin/bash
cd /root/checkin24hs

echo "=== CORRIGIENDO TODOS LOS CONTENEDORES ==="
echo ""

docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        echo "=== Verificando $container ==="
        container_line_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        
        if echo "$container_line_5150" | grep -q "editHotelName"; then
            echo "  OK: Línea 5150 correcta"
        else
            echo "  ERROR: Línea 5150 incorrecta, corrigiendo..."
            docker cp deploy/dashboard.html $container:/app/dashboard.html
            docker restart $container > /dev/null 2>&1
            echo "  Corregido y reiniciado"
        fi
        echo ""
    fi
done

echo "=== VERIFICACIÓN FINAL ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    line_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if echo "$line_5150" | grep -q "editHotelName"; then
        echo "✅ $container: OK"
    else
        echo "❌ $container: ERROR"
    fi
done
