#!/bin/bash

echo "🔧 Solucionando problema 404 del dashboard..."
echo ""

# 1. Verificar y actualizar servicio con labels de Traefik
echo "=== 1. Configurando Traefik para el dashboard ==="
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -i dashboard | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio de dashboard"
    echo "   Servicios disponibles:"
    docker service ls
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Agregar/actualizar labels de Traefik
echo "=== 2. Agregando labels de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --label-add "traefik.http.routers.dashboard.middlewares=dashboard-headers" \
  --label-add "traefik.http.middlewares.dashboard-headers.headers.customrequestheaders.X-Forwarded-Proto=https" \
  $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Labels de Traefik agregados correctamente"
else
    echo "⚠️ Error al agregar labels (puede que ya existan)"
fi
echo ""

# 3. Asegurar que el servicio tenga réplicas
echo "=== 3. Verificando réplicas del servicio ==="
REPLICAS=$(docker service inspect $SERVICE_NAME --format '{{.Spec.Mode.Replicated.Replicas}}' 2>/dev/null)
echo "Réplicas actuales: $REPLICAS"

if [ "$REPLICAS" = "0" ] || [ -z "$REPLICAS" ]; then
    echo "⚠️ El servicio no tiene réplicas, escalando a 1..."
    docker service scale ${SERVICE_NAME}=1
    sleep 5
fi
echo ""

# 4. Verificar que los contenedores estén corriendo
echo "=== 4. Verificando contenedores ==="
RUNNING=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}" | wc -l)
echo "Contenedores corriendo: $RUNNING"

if [ "$RUNNING" -eq 0 ]; then
    echo "⚠️ No hay contenedores corriendo, esperando 10 segundos..."
    sleep 10
    RUNNING=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}" | wc -l)
    echo "Contenedores corriendo después de esperar: $RUNNING"
fi
echo ""

# 5. Verificar logs recientes
echo "=== 5. Últimos logs del servicio ==="
docker service logs --tail 10 $SERVICE_NAME 2>&1 | tail -10
echo ""

# 6. Probar acceso local
echo "=== 6. Probando acceso local al puerto 3000 ==="
sleep 3
curl -I http://localhost:3000 2>&1 | head -5 || echo "⚠️ No se pudo conectar al puerto 3000 localmente"
echo ""

echo "✅ Proceso completado"
echo ""
echo "📝 Próximos pasos:"
echo "1. Espera 30-60 segundos para que Traefik actualice la configuración"
echo "2. Recarga el dashboard en el navegador (Ctrl+Shift+R)"
echo "3. Si aún hay 404, verifica los logs de Traefik:"
echo "   docker logs \$(docker ps --format '{{.Names}}' | grep traefik) --tail 50"








