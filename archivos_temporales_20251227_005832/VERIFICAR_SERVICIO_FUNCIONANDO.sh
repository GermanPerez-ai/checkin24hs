#!/bin/bash

echo "=========================================="
echo "Verificar que el Servicio está Funcionando"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio
echo "=== Estado del servicio ==="
docker service ps checkin24hs_dashboard --no-trunc | head -5
echo ""

# 2. Verificar contenedor corriendo
echo "=== Contenedor corriendo ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "✅ Contenedor: $CONTAINER_ID"
    echo ""
    
    # Verificar proceso
    echo "=== Proceso corriendo ==="
    docker exec $CONTAINER_ID ps aux | grep node
    echo ""
    
    # Probar acceso
    echo "=== Probar acceso ==="
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -5
    echo ""
    
    # Ver logs
    echo "=== Logs (últimas 5 líneas) ==="
    docker logs $CONTAINER_ID --tail 5 2>&1
else
    echo "❌ No hay contenedor corriendo"
fi

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""




