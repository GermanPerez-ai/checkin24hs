#!/bin/bash
# Script definitivo para configurar Traefik para el dashboard

echo "=========================================="
echo "🔧 Configurando Traefik - Solución Definitiva"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

echo "1️⃣ Verificando estado del servicio..."
SERVICE_STATUS=$(docker service ls | grep "$DASHBOARD_SERVICE" | awk '{print $4}')

if [ -z "$SERVICE_STATUS" ]; then
    echo "❌ El servicio NO está corriendo"
    exit 1
fi

echo "✅ Servicio está: $SERVICE_STATUS"
echo ""

echo "2️⃣ Verificando acceso directo al servidor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo "Probando acceso directo..."

docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    console.log('Status:', res.statusCode);
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1

if [ $? -ne 0 ]; then
    echo "❌ El servidor NO responde correctamente"
    exit 1
fi

echo "✅ El servidor responde correctamente"
echo ""

echo "3️⃣ Verificando red del servicio..."
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
        echo "⚠️ La red $NETWORK no existe"
        echo "Se creará automáticamente al agregar el servicio"
        docker service update --network-add "$NETWORK" "$DASHBOARD_SERVICE"
        echo "Esperando 10 segundos..."
        sleep 10
    fi
fi

echo ""
echo "4️⃣ Eliminando TODAS las etiquetas Traefik anteriores..."
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
echo "5️⃣ Aplicando etiquetas Traefik con router único..."
ROUTER_NAME="dashboard-checkin24hs-$(date +%s)"
echo "   Router único: $ROUTER_NAME"

docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.$ROUTER_NAME.rule=Host(\`$DOMAIN\`)" \
    --label-add "traefik.http.routers.$ROUTER_NAME.entrypoints=websecure" \
    --label-add "traefik.http.routers.$ROUTER_NAME.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.$ROUTER_NAME.service=$ROUTER_NAME" \
    --label-add "traefik.http.services.$ROUTER_NAME.loadbalancer.server.port=$PORT" \
    --label-add "traefik.docker.network=$NETWORK" \
    --label-add "traefik.http.routers.$ROUTER_NAME.middlewares=dashboard-headers" \
    --label-add "traefik.http.middlewares.dashboard-headers.headers.customRequestHeaders.X-Forwarded-Proto=https" \
    "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas aplicadas correctamente"
else
    echo "❌ Error al aplicar etiquetas"
    exit 1
fi

echo ""
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "7️⃣ Verificando etiquetas aplicadas..."
SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)
TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ Las etiquetas NO se aplicaron"
    echo ""
    echo "⚠️ EasyPanel está sobrescribiendo las etiquetas"
    echo ""
    echo "✅ SOLUCIÓN: Configurar dominio desde EasyPanel"
    echo ""
    echo "📋 PASOS EN EASYPANEL:"
    echo ""
    echo "   1. Ve a EasyPanel → Proyecto checkin24hs → Servicio dashboard"
    echo "   2. Pestaña: '🔗 Dominios' o 'Domains'"
    echo "   3. Clic: 'Agregar Dominio' o 'Add Domain'"
    echo "   4. Ingresa: $DOMAIN"
    echo "   5. Configura:"
    echo "      ✅ HTTPS: Activado"
    echo "      ✅ Puerto destino: $PORT"
    echo "      ✅ Ruta destino: /"
    echo "   6. Guarda"
    echo "   7. Espera 1-2 minutos"
    echo ""
    echo "   EasyPanel aplicará las etiquetas automáticamente"
else
    echo "✅ Etiquetas Traefik aplicadas:"
    echo "$TRAEFIK_LABELS" | head -10
fi

echo ""
echo "8️⃣ Verificando acceso a través de Traefik..."
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN" 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Dashboard accesible a través de Traefik (HTTP 200)"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️ No se pudo conectar (posible problema de DNS o Traefik)"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "❌ Error 404 - Traefik no está enrutando correctamente"
    else
        echo "⚠️ Código HTTP: $HTTP_CODE"
    fi
else
    echo "⚠️ curl no está disponible, prueba manualmente: https://$DOMAIN"
fi

echo ""
echo "9️⃣ Verificando logs de Traefik..."
TRAEFIK_LOGS=$(docker service logs traefik --tail 20 2>&1 | grep -iE "(dashboard|error|router)" | tail -5)

if [ -z "$TRAEFIK_LOGS" ]; then
    echo "✅ No hay errores relevantes en Traefik"
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
    echo "⏳ Espera 1-2 minutos y prueba:"
    echo "   https://$DOMAIN"
else
    echo "❌ Las etiquetas NO se aplicaron"
    echo ""
    echo "✅ SOLUCIÓN: Configura el dominio desde EasyPanel (pasos arriba)"
fi

echo ""
echo "Para verificar etiquetas:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq"
echo ""
