#!/bin/bash
# Script para diagnosticar el error 504 Gateway Timeout

echo "=========================================="
echo "Diagnostico de 504 Gateway Timeout"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio
echo "1. Estado del servicio checkin24hs_dashboard:"
docker service ps checkin24hs_dashboard --no-trunc
echo ""

# 2. Ver contenedores corriendo
echo "2. Contenedores corriendo:"
docker ps | grep checkin24hs_dashboard
echo ""

# 3. Ver logs del servicio (últimas 50 líneas)
echo "3. Logs del servicio (ultimas 50 lineas):"
docker service logs checkin24hs_dashboard --tail 50
echo ""

# 4. Verificar contenedor específico
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "4. Informacion del contenedor $CONTAINER_ID:"
    echo "   - Estado:"
    docker inspect $CONTAINER_ID --format='{{.State.Status}}'
    echo ""
    echo "   - Procesos corriendo:"
    docker exec $CONTAINER_ID ps aux || echo "   ERROR: No se puede ejecutar ps en el contenedor"
    echo ""
    echo "   - Archivos en /app:"
    docker exec $CONTAINER_ID ls -lah /app/ | head -20
    echo ""
    echo "   - Verificar que dashboard.html existe:"
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null && echo "   OK: dashboard.html existe" || echo "   ERROR: dashboard.html NO existe"
    echo ""
    echo "   - Verificar que showSection esta en el archivo:"
    docker exec $CONTAINER_ID head -50 /app/dashboard.html | grep -q "window.showSection" && echo "   OK: showSection encontrada" || echo "   ERROR: showSection NO encontrada"
    echo ""
    echo "   - Probar acceso interno al puerto 3000:"
    docker exec $CONTAINER_ID wget -q -O- http://localhost:3000 2>&1 | head -5 || echo "   ERROR: No se puede acceder al puerto 3000"
    echo ""
    echo "   - Logs del contenedor (ultimas 30 lineas):"
    docker logs $CONTAINER_ID --tail 30
else
    echo "4. ERROR: No hay contenedor corriendo"
fi

echo ""
echo "=========================================="
echo "Diagnostico completado"
echo "=========================================="


