#!/bin/bash
# Script para corregir automáticamente todos los contenedores con error

cd /root/checkin24hs

echo "=== CORRIGIENDO TODOS LOS CONTENEDORES CON ERROR ==="
echo ""

# Función para corregir un contenedor
corregir_contenedor() {
    local container=$1
    echo "Corrigiendo $container..."
    docker stop $container > /dev/null 2>&1
    sleep 1
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker start $container > /dev/null 2>&1
    sleep 2
    
    # Verificar
    line=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if echo "$line" | grep -q "editHotelName"; then
        echo "  ✅ Corregido correctamente"
        return 0
    else
        echo "  ❌ Error al corregir"
        return 1
    fi
}

# Verificar y corregir todos los contenedores
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        line=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        if ! echo "$line" | grep -q "editHotelName"; then
            corregir_contenedor "$container"
        fi
    fi
done

echo ""
echo "=== VERIFICACIÓN FINAL ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    line=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if echo "$line" | grep -q "editHotelName"; then
        echo "✅ $container: OK"
    else
        echo "❌ $container: ERROR"
    fi
done

echo ""
echo "=== PROCESO COMPLETADO ==="








