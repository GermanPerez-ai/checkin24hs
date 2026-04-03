#!/bin/bash

echo "=========================================="
echo "Diagnosticar y Reparar Servidor"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 2. Verificar qué proceso está corriendo
echo "=== PASO 1: Verificar proceso ==="
docker exec $CONTAINER_ID ps aux
echo ""

# 3. Verificar qué archivo está ejecutando
echo "=== PASO 2: Verificar archivo ejecutándose ==="
docker exec $CONTAINER_ID cat /proc/$(docker exec $CONTAINER_ID pgrep -f "node")/cmdline 2>/dev/null | tr '\0' ' ' || echo "No se pudo obtener"
echo ""
echo ""

# 4. Verificar puertos abiertos
echo "=== PASO 3: Verificar puertos abiertos ==="
docker exec $CONTAINER_ID netstat -tlnp 2>&1 || docker exec $CONTAINER_ID ss -tlnp 2>&1
echo ""

# 5. Verificar archivos en /app
echo "=== PASO 4: Verificar archivos en /app ==="
docker exec $CONTAINER_ID ls -la /app/
echo ""

# 6. Verificar si server.js o serve-dashboard.js existe
echo "=== PASO 5: Verificar archivos de servidor ==="
docker exec $CONTAINER_ID ls -lh /app/server.js /app/serve-dashboard.js 2>&1
echo ""

# 7. Verificar contenido de server.js (primeras líneas)
echo "=== PASO 6: Ver contenido de server.js ==="
docker exec $CONTAINER_ID head -20 /app/server.js 2>&1
echo ""

# 8. Verificar variables de entorno
echo "=== PASO 7: Verificar variables de entorno ==="
docker exec $CONTAINER_ID env | grep -E "PORT|NODE"
echo ""

# 9. Probar conexión desde el host
echo "=== PASO 8: Probar conexión desde el host ==="
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del contenedor: $CONTAINER_IP"
curl -I --connect-timeout 5 http://$CONTAINER_IP:3000 2>&1 | head -5
echo ""

# 10. Verificar logs completos
echo "=== PASO 9: Ver logs completos del contenedor ==="
docker logs $CONTAINER_ID --tail 50 2>&1
echo ""

# 11. Verificar si el problema es que está usando server.js en vez de serve-dashboard.js
echo "=== PASO 10: Verificar Dockerfile/CMD ==="
docker inspect $CONTAINER_ID --format '{{.Config.Cmd}}' 2>&1
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
echo ""

# Si el problema es que está usando server.js, necesitamos verificar qué hace ese archivo
echo "Si el servidor está usando server.js en vez de serve-dashboard.js,"
echo "necesitamos verificar qué hace server.js y posiblemente cambiarlo."
echo ""




