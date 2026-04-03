#!/bin/bash
# Corregir Traefik para resolver error 404 de forma definitiva

echo "=========================================="
echo "🔧 Corrigiendo Traefik para resolver 404"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

echo "1️⃣ Verificando que el servidor responde correctamente..."
FIRST_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "Verificando servicios..."
    docker service ls | grep dashboard
    exit 1
fi

echo "Contenedor: $FIRST_CONTAINER"
echo "Probando acceso directo..."
docker exec "$FIRST_CONTAINER" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4}, (res) => {
    console.log('Status:', res.statusCode);
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1

if [ $? -ne 0 ]; then
    echo "❌ El servidor NO responde correctamente"
    echo "El problema está en el servidor, no en Traefik"
    exit 1
fi

echo "✅ El servidor responde correctamente"
echo ""

echo "2️⃣ Verificando red del servicio..."
SERVICE_NETWORKS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)

if echo "$SERVICE_NETWORKS" | grep -q "$NETWORK"; then
    echo "✅ El servicio está en la red $NETWORK"
else
    echo "⚠️ El servicio NO está en la red $NETWORK"
    echo "Verificando si la red existe..."
    if docker network ls | grep -q "$NETWORK"; then
        echo "Agregando el servicio a la red $NETWORK..."
        docker service update --network-add "$NETWORK" "$DASHBOARD_SERVICE"
        echo "Esperando 10 segundos..."
        sleep 10
    else
        echo "⚠️ La red $NETWORK no existe. Se creará automáticamente al agregar el servicio."
        echo "Agregando el servicio a la red $NETWORK..."
        docker service update --network-add "$NETWORK" "$DASHBOARD_SERVICE"
        echo "Esperando 10 segundos..."
        sleep 10
    fi
fi

echo ""
echo "3️⃣ Eliminando TODAS las etiquetas Traefik existentes..."
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
    "$DASHBOARD_SERVICE" 2>/dev/null || echo "No había etiquetas previas"

echo ""
echo "Esperando 10 segundos..."
sleep 10

echo ""
echo "4️⃣ Aplicando etiquetas Traefik (MÉTODO COMPLETO)..."
echo "   Dominio: $DOMAIN"
echo "   Puerto: $PORT"
echo "   Red: $NETWORK"
echo ""

# Aplicar todas las etiquetas en un solo comando (sin --network-add para evitar error si ya está)
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
    echo "✅ Etiquetas Traefik aplicadas correctamente"
else
    echo "❌ Error al aplicar las etiquetas"
    exit 1
fi

echo ""
echo "5️⃣ Esperando 30 segundos para que el servicio se actualice..."
sleep 30

echo ""
echo "6️⃣ Verificando etiquetas aplicadas..."
echo ""

# Verificar en el servicio
SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)
TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ PROBLEMA: Las etiquetas NO se aplicaron"
    echo ""
    echo "🔍 DIAGNÓSTICO:"
    echo "   EasyPanel está sobrescribiendo las etiquetas automáticamente"
    echo ""
    echo "✅ SOLUCIÓN OBLIGATORIA:"
    echo "   Debes configurar el dominio desde EasyPanel"
    echo ""
    echo "📋 PASOS EN EASYPANEL:"
    echo ""
    echo "   1. Abre: http://72.61.58.240:3000"
    echo "   2. Proyecto: checkin24hs"
    echo "   3. Servicio: dashboard"
    echo "   4. Pestaña: '🔗 Dominios' o 'Domains'"
    echo "   5. Clic: 'Agregar Dominio' o 'Add Domain'"
    echo "   6. Ingresa: $DOMAIN"
    echo "   7. Configura:"
    echo "      ✅ HTTPS: Activado"
    echo "      ✅ Puerto destino: $PORT"
    echo "      ✅ Ruta destino: /"
    echo "   8. Guarda"
    echo "   9. Espera 1-2 minutos"
    echo ""
    echo "   EasyPanel aplicará las etiquetas automáticamente"
    echo ""
    exit 1
else
    echo "✅ Etiquetas Traefik aplicadas:"
    echo "$TRAEFIK_LABELS"
fi

echo ""
echo "7️⃣ Verificando en contenedores..."
CONTAINER_IDS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")
FOUND_IN_CONTAINER=false

for container_id in $CONTAINER_IDS; do
    CONTAINER_LABELS=$(docker inspect "$container_id" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
    if [ ! -z "$CONTAINER_LABELS" ]; then
        echo "✅ Contenedor $container_id tiene etiquetas Traefik"
        FOUND_IN_CONTAINER=true
    fi
done

if [ "$FOUND_IN_CONTAINER" = false ]; then
    echo "⚠️ Las etiquetas no aparecen en los contenedores aún"
    echo "   Esto puede tardar unos segundos más"
fi

echo ""
echo "8️⃣ Esperando 30 segundos más para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "9️⃣ Verificando logs de Traefik..."
TRAEFIK_LOGS=$(docker service logs traefik --tail 30 2>&1 | grep -iE "(dashboard|error|router)" | tail -10)

if [ -z "$TRAEFIK_LOGS" ]; then
    echo "✅ No se encontraron errores relevantes en Traefik"
else
    echo "⚠️ Logs de Traefik:"
    echo "$TRAEFIK_LOGS"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ ! -z "$TRAEFIK_LABELS" ]; then
    echo "✅ Etiquetas Traefik aplicadas correctamente"
    echo ""
    echo "⏳ Espera 1-2 minutos y prueba acceder a:"
    echo "   https://$DOMAIN"
    echo ""
    echo "Si aún no funciona, verifica:"
    echo "   1. Que el DNS apunte correctamente a este servidor"
    echo "   2. Que Traefik esté corriendo: docker service ls | grep traefik"
    echo "   3. Los logs de Traefik: docker service logs traefik --tail 50"
else
    echo "❌ Las etiquetas NO se aplicaron"
    echo ""
    echo "🔍 CAUSA: EasyPanel está sobrescribiendo las etiquetas"
    echo ""
    echo "✅ SOLUCIÓN: Configura el dominio desde EasyPanel (pasos arriba)"
fi

echo ""
echo "=========================================="
echo "🔧 COMANDOS PARA VERIFICAR"
echo "=========================================="
echo ""
echo "Ver etiquetas del servicio:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq"
echo ""
echo "Ver logs de Traefik:"
echo "  docker service logs traefik --tail 50 | grep -i dashboard"
echo ""
echo "Probar acceso directo:"
echo "  docker exec $FIRST_CONTAINER curl -s http://127.0.0.1:3000/ | head -20"
echo ""
