#!/bin/bash

cd /root/checkin24hs

echo "=== Diagnóstico de Gateway Timeout ==="
echo ""

# 1. Verificar estado del contenedor
echo "=== 1. Estado del contenedor ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor activo"
    docker ps -a | grep dashboard
    exit 1
fi

echo "✅ Contenedor activo: $CONTAINER"
docker ps | grep dashboard

# 2. Verificar recursos del contenedor
echo ""
echo "=== 2. Uso de recursos ==="
docker stats "$CONTAINER" --no-stream

# 3. Verificar logs recientes (últimas 50 líneas)
echo ""
echo "=== 3. Logs recientes (últimas 50 líneas) ==="
docker logs "$CONTAINER" --tail 50 2>&1 | tail -50

# 4. Verificar si el puerto 3000 responde
echo ""
echo "=== 4. Verificando respuesta del puerto 3000 ==="
timeout 5 docker exec "$CONTAINER" curl -s -o /dev/null -w "HTTP: %{http_code}, Tiempo: %{time_total}s\n" http://localhost:3000/ || echo "❌ Timeout o error al conectar"

# 5. Verificar procesos dentro del contenedor
echo ""
echo "=== 5. Procesos en el contenedor ==="
docker exec "$CONTAINER" ps aux | head -10

# 6. Verificar logs de Traefik
echo ""
echo "=== 6. Logs de Traefik (últimas 20 líneas) ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs "$TRAEFIK_CONTAINER" --tail 20 2>&1 | grep -iE "dashboard|timeout|502|504|error" | tail -20 || echo "No se encontraron errores relacionados"
else
    echo "⚠️ No se encontró Traefik"
fi

# 7. Verificar servicio Docker Swarm
echo ""
echo "=== 7. Estado del servicio Docker Swarm ==="
docker service ps checkin24hs_dashboard --no-trunc | head -10

# 8. Verificar memoria y CPU del sistema
echo ""
echo "=== 8. Recursos del sistema ==="
free -h
echo ""
top -bn1 | head -5

echo ""
echo "=== Diagnóstico completado ==="


