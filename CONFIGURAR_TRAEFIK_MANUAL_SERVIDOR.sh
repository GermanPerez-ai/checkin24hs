#!/bin/bash
# Configurar Traefik manualmente desde el servidor

echo "=========================================="
echo "🔧 Configurando Traefik manualmente"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

echo "1️⃣ Verificando servicios..."
docker service ls | grep -E "(dashboard|traefik)" || echo "⚠️ Servicios no encontrados"

echo ""
echo "2️⃣ Verificando red easypanel..."
docker network ls | grep easypanel || echo "⚠️ Red easypanel no encontrada"

echo ""
echo "3️⃣ Eliminando etiquetas Traefik existentes del dashboard (si las hay)..."
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
    "$DASHBOARD_SERVICE" 2>/dev/null || echo "No había etiquetas previas o ya fueron eliminadas"

echo ""
echo "Esperando 5 segundos..."
sleep 5

echo ""
echo "4️⃣ Aplicando etiquetas Traefik al dashboard..."
echo "   Dominio: $DOMAIN"
echo "   Puerto: $PORT"
echo "   Red: $NETWORK"
echo ""

docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`$DOMAIN\`)" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.service=dashboard-checkin24hs" \
    --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=$PORT" \
    --label-add "traefik.docker.network=$NETWORK" \
    "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Comando ejecutado correctamente"
else
    echo "❌ Error al ejecutar el comando"
    exit 1
fi

echo ""
echo "5️⃣ Esperando 15 segundos para que el servicio se actualice..."
sleep 15

echo ""
echo "6️⃣ Verificando etiquetas aplicadas al servicio..."
echo ""
SERVICE_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik)

if [ -z "$SERVICE_LABELS" ]; then
    echo "❌ No se encontraron etiquetas Traefik en el servicio"
    echo ""
    echo "Intentando método alternativo..."
    echo ""
    
    # Método alternativo: usar formato JSON
    echo "Verificando formato JSON..."
    docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null || echo "No se encontraron etiquetas en JSON"
else
    echo "✅ Etiquetas encontradas:"
    echo "$SERVICE_LABELS"
fi

echo ""
echo "7️⃣ Verificando etiquetas en los contenedores..."
CONTAINER_IDS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")
FOUND_LABELS=false

for container_id in $CONTAINER_IDS; do
    echo "Contenedor: $container_id"
    CONTAINER_LABELS=$(docker inspect "$container_id" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik)
    
    if [ ! -z "$CONTAINER_LABELS" ]; then
        echo "✅ Etiquetas encontradas en el contenedor:"
        echo "$CONTAINER_LABELS"
        FOUND_LABELS=true
    else
        echo "⚠️ No se encontraron etiquetas en este contenedor"
    fi
    echo ""
done

echo ""
echo "8️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "9️⃣ Verificando logs de Traefik..."
echo ""
TRAEFIK_LOGS=$(docker service logs traefik --tail 30 2>&1 | grep -iE "(dashboard|error|router)" | tail -10)

if [ -z "$TRAEFIK_LOGS" ]; then
    echo "⚠️ No se encontraron logs relevantes de Traefik"
    echo "Mostrando últimos logs de Traefik:"
    docker service logs traefik --tail 10
else
    echo "Logs relevantes de Traefik:"
    echo "$TRAEFIK_LOGS"
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Servicio: $DASHBOARD_SERVICE"
echo "Dominio: $DOMAIN"
echo "Puerto: $PORT"
echo "Red: $NETWORK"
echo ""

if [ "$FOUND_LABELS" = true ] || [ ! -z "$SERVICE_LABELS" ]; then
    echo "✅ Etiquetas Traefik aplicadas"
    echo ""
    echo "Espera 1-2 minutos y prueba acceder a:"
    echo "  https://$DOMAIN"
    echo ""
    echo "Si aún no funciona, verifica:"
    echo "  1. Que el DNS apunte correctamente a este servidor"
    echo "  2. Que Traefik esté corriendo: docker service ls | grep traefik"
    echo "  3. Los logs de Traefik: docker service logs traefik --tail 50"
else
    echo "⚠️ Las etiquetas no se aplicaron correctamente"
    echo ""
    echo "Posibles causas:"
    echo "  1. EasyPanel está sobrescribiendo las etiquetas"
    echo "  2. El servicio no existe o tiene otro nombre"
    echo "  3. Problema con Docker Swarm"
    echo ""
    echo "Verifica el nombre del servicio:"
    echo "  docker service ls | grep dashboard"
fi
echo ""
