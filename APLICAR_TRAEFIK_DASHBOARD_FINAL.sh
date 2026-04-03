#!/bin/bash
# Aplicar etiquetas Traefik al dashboard de forma definitiva

echo "=========================================="
echo "🔧 Aplicando etiquetas Traefik al dashboard"
echo "=========================================="
echo ""

echo "1️⃣ Verificando servicios..."
DASHBOARD_SERVICE="checkin24hs_dashboard"
CRM_SERVICE="checkin24hs_crm"

echo "Dashboard: $DASHBOARD_SERVICE"
echo "CRM: $CRM_SERVICE"
echo ""

echo "2️⃣ Eliminando etiquetas Traefik del CRM (para evitar conflictos)..."
docker service update --label-rm "traefik.enable" \
    --label-rm "traefik.http.routers.crm.rule" \
    --label-rm "traefik.http.routers.crm.entrypoints" \
    --label-rm "traefik.http.routers.crm.tls.certresolver" \
    --label-rm "traefik.http.services.crm.loadbalancer.server.port" \
    --label-rm "traefik.docker.network" \
    "$CRM_SERVICE" 2>/dev/null || echo "CRM no tiene etiquetas o ya fueron eliminadas"

echo ""
echo "Esperando 5 segundos..."
sleep 5

echo ""
echo "3️⃣ Aplicando etiquetas Traefik al dashboard con router único..."
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.service=dashboard-checkin24hs" \
    --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
    --label-add "traefik.docker.network=easypanel" \
    "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas aplicadas correctamente"
else
    echo "❌ Error al aplicar etiquetas"
    exit 1
fi

echo ""
echo "4️⃣ Esperando 10 segundos para que el servicio se actualice..."
sleep 10

echo ""
echo "5️⃣ Verificando etiquetas aplicadas..."
echo ""
echo "--- Etiquetas del servicio dashboard ---"
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "⚠️ No se encontraron etiquetas Traefik"

echo ""
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "7️⃣ Verificando logs de Traefik (últimas 15 líneas)..."
docker service logs traefik --tail 15 | tail -10

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "✅ Etiquetas Traefik aplicadas al dashboard"
echo "✅ Router único: dashboard-checkin24hs"
echo "✅ Dominio: dashboard.checkin24hs.com"
echo "✅ Puerto: 3000"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  https://dashboard.checkin24hs.com"
echo ""
echo "Si aún no funciona, verifica:"
echo "  1. Que Traefik esté corriendo: docker service ls | grep traefik"
echo "  2. Que el servicio esté en la red easypanel"
echo "  3. Los logs de Traefik: docker service logs traefik --tail 50"
echo ""
