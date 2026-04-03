#!/bin/bash
# Verificar si las etiquetas se aplicaron correctamente

echo "=========================================="
echo "🔍 Verificando etiquetas aplicadas"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando TODAS las etiquetas del servicio..."
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}'

echo ""
echo "2️⃣ Verificando etiquetas Traefik específicamente..."
TRAEFIK_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ NO se encontraron etiquetas Traefik"
    echo ""
    echo "3️⃣ Agregando etiquetas Traefik nuevamente..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=web" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.tls=true" \
      --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
      "$DASHBOARD_SERVICE"
    
    echo ""
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "Verificando nuevamente..."
    docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik
else
    echo "✅ Etiquetas Traefik encontradas:"
    echo "$TRAEFIK_LABELS"
fi

echo ""
echo "4️⃣ Verificando si Traefik detecta el servicio..."
echo "   Esperando 20 segundos para que Traefik actualice..."
sleep 20

docker service logs traefik --tail 50 | grep -iE "dashboard-checkin24hs|dashboard.checkin24hs.com" | tail -10 || echo "No se encontraron logs relacionados"

echo ""
echo "5️⃣ Verificando contenedores del dashboard para ver si tienen las etiquetas..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Contenedor: $DASHBOARD_CONTAINER"
    echo "Etiquetas del contenedor:"
    docker inspect "$DASHBOARD_CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik | head -10
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Si las etiquetas están aplicadas pero Traefik no las detecta,"
echo "puede ser necesario reiniciar Traefik o esperar más tiempo."
echo ""
