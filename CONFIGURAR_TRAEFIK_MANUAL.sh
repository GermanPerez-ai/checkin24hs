#!/bin/bash
# Script para configurar Traefik manualmente para el dashboard

echo "=========================================="
echo "🔧 Configurando Traefik Manualmente"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

echo "1️⃣ Eliminando etiquetas Traefik anteriores..."
docker service update \
    --label-rm "traefik.enable" \
    --label-rm "traefik.http.routers.dashboard.rule" \
    --label-rm "traefik.http.routers.dashboard.entrypoints" \
    --label-rm "traefik.http.routers.dashboard.tls.certresolver" \
    --label-rm "traefik.http.routers.dashboard.service" \
    --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
    --label-rm "traefik.http.routers.dashboard-checkin24hs.rule" \
    --label-rm "traefik.http.routers.dashboard-checkin24hs.entrypoints" \
    --label-rm "traefik.http.routers.dashboard-checkin24hs.tls.certresolver" \
    --label-rm "traefik.http.routers.dashboard-checkin24hs.service" \
    --label-rm "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port" \
    --label-rm "traefik.docker.network" \
    --label-rm "traefik.http.middlewares.dashboard-headers.headers.customRequestHeaders.X-Forwarded-Proto" \
    --label-rm "traefik.http.routers.dashboard-checkin24hs.middlewares" \
    "$DASHBOARD_SERVICE" 2>/dev/null || echo "✓ Sin etiquetas previas"

echo ""
echo "Esperando 5 segundos..."
sleep 5

echo ""
echo "2️⃣ Aplicando etiquetas Traefik..."
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`$DOMAIN\`)" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.service=dashboard-checkin24hs" \
    --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=$PORT" \
    --label-add "traefik.docker.network=$NETWORK" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.middlewares=dashboard-headers" \
    --label-add "traefik.http.middlewares.dashboard-headers.headers.customRequestHeaders.X-Forwarded-Proto=https" \
    "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas aplicadas correctamente"
else
    echo "❌ Error al aplicar etiquetas"
    exit 1
fi

echo ""
echo "3️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "4️⃣ Verificando etiquetas aplicadas..."
SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)
TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ Las etiquetas NO se aplicaron"
    echo ""
    echo "⚠️ EasyPanel puede estar sobrescribiendo las etiquetas"
    echo "   Configura el dominio desde EasyPanel → Dominios"
else
    echo "✅ Etiquetas Traefik aplicadas:"
    echo "$TRAEFIK_LABELS" | head -10
fi

echo ""
echo "5️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 20 2>&1 | grep -iE "(dashboard|error)" | tail -5 || echo "✓ Sin errores relevantes"

echo ""
echo "=========================================="
echo "✅ Configuración completada"
echo "=========================================="
echo ""
echo "Espera 1-2 minutos y prueba:"
echo "  https://$DOMAIN"
echo ""
echo "Para verificar etiquetas:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq"
echo ""
