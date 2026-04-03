#!/bin/bash

echo "=========================================="
echo "Diagnosticar Servidor que No Responde"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar proceso
echo "=== 1. Proceso corriendo ==="
docker exec $CONTAINER_ID ps aux | grep node
echo ""

# 2. Verificar puerto
echo "=== 2. Verificar puerto 3000 ==="
docker exec $CONTAINER_ID netstat -tlnp 2>&1 | grep 3000 || docker exec $CONTAINER_ID ss -tlnp 2>&1 | grep 3000 || echo "No se encontró puerto 3000 escuchando"
echo ""

# 3. Ver logs completos
echo "=== 3. Logs completos del contenedor ==="
docker logs $CONTAINER_ID --tail 50 2>&1
echo ""

# 4. Verificar si server.js tiene errores
echo "=== 4. Verificar server.js ==="
docker exec $CONTAINER_ID node -e "console.log('Node funciona')" 2>&1
echo ""

# 5. Intentar ejecutar server.js manualmente para ver errores
echo "=== 5. Intentar ejecutar server.js manualmente ==="
docker exec $CONTAINER_ID timeout 3 node /app/server.js 2>&1 || echo "Timeout o error al ejecutar"
echo ""

# 6. Verificar dependencias
echo "=== 6. Verificar dependencias ==="
docker exec $CONTAINER_ID ls -lh /app/puppeteer-real-cotizacion.js 2>&1
echo ""

# 7. Verificar si hay errores de módulos faltantes
echo "=== 7. Verificar módulos de Node ==="
docker exec $CONTAINER_ID node -e "require('/app/server.js')" 2>&1 | head -20
echo ""

# 8. Verificar IP del contenedor y probar desde el host
echo "=== 8. Verificar IP y probar desde host ==="
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor: $CONTAINER_IP"
curl -v --connect-timeout 5 http://$CONTAINER_IP:3000 2>&1 | head -15
echo ""

# 9. Verificar configuración de Traefik
echo "=== 9. Verificar configuración Traefik ==="
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
echo ""




