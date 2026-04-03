#!/bin/bash
# Script para solucionar Connection Refused en el puerto 3000

echo "=========================================="
echo "Solucionando Connection Refused"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No hay contenedor corriendo"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar si el puerto está escuchando
echo "1. Verificando puerto 3000:"
docker exec $CONTAINER_ID netstat -tlnp 2>/dev/null | grep 3000 || docker exec $CONTAINER_ID ss -tlnp 2>/dev/null | grep 3000 || echo "   ERROR: Puerto 3000 NO esta escuchando"
echo ""

# 2. Ver logs completos del contenedor
echo "2. Logs completos del contenedor:"
docker logs $CONTAINER_ID 2>&1 | tail -50
echo ""

# 3. Verificar qué archivo está ejecutando
echo "3. Archivo que se esta ejecutando:"
docker exec $CONTAINER_ID ps aux | grep node
echo ""

# 4. Verificar si server.js existe y su contenido
echo "4. Verificando server.js:"
docker exec $CONTAINER_ID ls -lh /app/server.js 2>/dev/null && echo "   OK: server.js existe" || echo "   ERROR: server.js NO existe"
echo ""

# 5. Verificar si serve-dashboard.js existe
echo "5. Verificando serve-dashboard.js:"
docker exec $CONTAINER_ID ls -lh /app/serve-dashboard.js 2>/dev/null && echo "   OK: serve-dashboard.js existe" || echo "   ERROR: serve-dashboard.js NO existe"
echo ""

# 6. Ver las primeras líneas de server.js para entender qué hace
echo "6. Primeras 30 lineas de server.js:"
docker exec $CONTAINER_ID head -30 /app/server.js
echo ""

# 7. Intentar ejecutar el servidor manualmente para ver errores
echo "7. Intentando ejecutar server.js manualmente (primeros errores):"
docker exec $CONTAINER_ID timeout 5 node /app/server.js 2>&1 | head -20 || echo "   (timeout o error)"
echo ""

echo "=========================================="
echo "Diagnostico completado"
echo "=========================================="


