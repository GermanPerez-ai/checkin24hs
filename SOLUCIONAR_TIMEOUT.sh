#!/bin/bash

cd /root/checkin24hs

echo "=== Solucionando Gateway Timeout ==="
echo ""

# 1. Limpiar contenedores antiguos
echo "=== 1. Limpiando contenedores antiguos ==="
docker ps -a | grep dashboard | grep -v "Up" | awk '{print $1}' | xargs -r docker rm -f
echo "✅ Contenedores antiguos limpiados"

# 2. Verificar cuántos contenedores están corriendo
echo ""
echo "=== 2. Contenedores activos ==="
ACTIVE_COUNT=$(docker ps | grep dashboard | wc -l)
echo "Contenedores activos: $ACTIVE_COUNT"

if [ "$ACTIVE_COUNT" -gt 1 ]; then
    echo "⚠️ Hay múltiples contenedores activos. Esto puede causar problemas."
    echo "Escalando el servicio a 1 réplica..."
    docker service scale checkin24hs_dashboard=1
    echo "Esperando 10 segundos..."
    sleep 10
fi

# 3. Verificar el contenedor actual
echo ""
echo "=== 3. Contenedor actual ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER"
docker ps | grep dashboard | head -1

# 4. Verificar logs del contenedor
echo ""
echo "=== 4. Logs del contenedor (últimas 10 líneas) ==="
docker logs "$CONTAINER" --tail 10 2>&1 | tail -10

# 5. Verificar memoria
echo ""
echo "=== 5. Uso de memoria ==="
docker stats "$CONTAINER" --no-stream

# 6. Aumentar timeout de Traefik
echo ""
echo "=== 6. Configurando timeout de Traefik ==="
docker service update \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --label-add "traefik.http.services.dashboard.loadbalancer.healthcheck.interval=30s" \
  --label-add "traefik.http.services.dashboard.loadbalancer.healthcheck.timeout=10s" \
  --label-add "traefik.http.services.dashboard.loadbalancer.healthcheck.path=/" \
  checkin24hs_dashboard

echo "Esperando 15 segundos..."
sleep 15

# 7. Verificar estado final
echo ""
echo "=== 7. Estado final ==="
docker service ps checkin24hs_dashboard --no-trunc | head -3

echo ""
echo "✅ Completado"
echo ""
echo "📋 Cambios aplicados:"
echo "  1. ✅ Contenedores antiguos limpiados"
echo "  2. ✅ Servicio escalado a 1 réplica"
echo "  3. ✅ Timeout de Traefik aumentado"
echo ""
echo "⚠️ Si el problema persiste:"
echo "  - Verifica los logs: docker logs $CONTAINER --tail 50"
echo "  - Verifica memoria del sistema: free -h"
echo "  - Reinicia el servicio: docker service update --force checkin24hs_dashboard"


