#!/bin/bash
# Aplicar Traefik manualmente de forma agresiva y persistente

echo "=========================================="
echo "🔧 Aplicando Traefik manualmente (MODO AGRESIVO)"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

echo "1️⃣ Verificando servicio dashboard..."
if ! docker service ls | grep -q "$DASHBOARD_SERVICE"; then
    echo "❌ Servicio $DASHBOARD_SERVICE no encontrado"
    echo "Servicios disponibles:"
    docker service ls
    exit 1
fi

echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"

echo ""
echo "2️⃣ Verificando red easypanel..."
if ! docker network ls | grep -q "$NETWORK"; then
    echo "⚠️ Red $NETWORK no encontrada"
    echo "Redes disponibles:"
    docker network ls
    echo ""
    echo "Intentando usar la primera red overlay disponible..."
    NETWORK=$(docker network ls --filter driver=overlay --format "{{.Name}}" | head -1)
    if [ -z "$NETWORK" ]; then
        echo "❌ No se encontró ninguna red overlay"
        exit 1
    fi
    echo "✅ Usando red: $NETWORK"
else
    echo "✅ Red encontrada: $NETWORK"
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
    "$DASHBOARD_SERVICE" 2>/dev/null || echo "No había etiquetas previas"

echo ""
echo "Esperando 10 segundos..."
sleep 10

echo ""
echo "4️⃣ Aplicando etiquetas Traefik (MÉTODO AGRESIVO)..."
echo "   Dominio: $DOMAIN"
echo "   Puerto: $PORT"
echo "   Red: $NETWORK"
echo ""

# Aplicar todas las etiquetas en un solo comando
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
    echo "✅ Comando ejecutado correctamente"
else
    echo "❌ Error al ejecutar el comando"
    exit 1
fi

echo ""
echo "5️⃣ Esperando 20 segundos para que el servicio se actualice completamente..."
sleep 20

echo ""
echo "6️⃣ Verificando etiquetas aplicadas (MÉTODO DETALLADO)..."
echo ""

# Método 1: Verificar en el servicio
echo "--- Método 1: Inspección del servicio ---"
SERVICE_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)

if [ -z "$SERVICE_LABELS" ]; then
    echo "❌ No se encontraron etiquetas Traefik en el servicio"
    echo ""
    echo "Intentando método alternativo (JSON)..."
    SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)
    if [ ! -z "$SERVICE_JSON" ] && [ "$SERVICE_JSON" != "null" ] && [ "$SERVICE_JSON" != "{}" ]; then
        echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null || echo "No se encontraron etiquetas Traefik en JSON"
    else
        echo "❌ El servicio no tiene etiquetas"
    fi
else
    echo "✅ Etiquetas encontradas en el servicio:"
    echo "$SERVICE_LABELS"
fi

echo ""
echo "--- Método 2: Verificar en contenedores activos ---"
CONTAINER_IDS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")
FOUND_IN_CONTAINER=false

for container_id in $CONTAINER_IDS; do
    echo "Verificando contenedor: $container_id"
    CONTAINER_LABELS=$(docker inspect "$container_id" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
    
    if [ ! -z "$CONTAINER_LABELS" ]; then
        echo "✅ Etiquetas encontradas en el contenedor:"
        echo "$CONTAINER_LABELS"
        FOUND_IN_CONTAINER=true
    else
        echo "⚠️ No se encontraron etiquetas en este contenedor"
    fi
    echo ""
done

echo ""
echo "7️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "8️⃣ Verificando logs de Traefik (últimas 20 líneas)..."
echo ""
TRAEFIK_LOGS=$(docker service logs traefik --tail 20 2>&1 | grep -iE "(dashboard|error|router)" | tail -10)

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
echo "📋 RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

if [ "$FOUND_IN_CONTAINER" = true ] || [ ! -z "$SERVICE_LABELS" ]; then
    echo "✅ Etiquetas Traefik aplicadas"
    echo ""
    echo "⏳ Espera 1-2 minutos y prueba acceder a:"
    echo "   https://$DOMAIN"
    echo ""
    echo "Si aún no funciona, verifica:"
    echo "   1. Que el DNS apunte correctamente a este servidor"
    echo "   2. Que Traefik esté corriendo: docker service ls | grep traefik"
    echo "   3. Los logs de Traefik: docker service logs traefik --tail 50"
else
    echo "❌ PROBLEMA: Las etiquetas NO se aplicaron correctamente"
    echo ""
    echo "🔍 CAUSA PROBABLE: EasyPanel está sobrescribiendo las etiquetas"
    echo ""
    echo "✅ SOLUCIÓN RECOMENDADA:"
    echo "   Configurar el dominio desde EasyPanel en lugar de aplicar etiquetas manualmente"
    echo ""
    echo "📋 PASOS EN EASYPANEL:"
    echo ""
    echo "   1. Ve a EasyPanel: http://72.61.58.240:3000"
    echo "   2. Ve al proyecto 'checkin24hs'"
    echo "   3. Ve al servicio 'dashboard'"
    echo "   4. Ve a la pestaña '🔗 Dominios' o 'Domains'"
    echo "   5. Haz clic en 'Agregar Dominio' o 'Add Domain'"
    echo "   6. Ingresa: $DOMAIN"
    echo "   7. Asegúrate de que:"
    echo "      - HTTPS esté activado"
    echo "      - Puerto destino: $PORT"
    echo "      - Ruta destino: /"
    echo "   8. Guarda los cambios"
    echo "   9. Espera 1-2 minutos"
    echo ""
    echo "   EasyPanel aplicará las etiquetas Traefik automáticamente"
    echo ""
    echo "🔄 ALTERNATIVA: Intentar aplicar etiquetas nuevamente"
    echo "   Ejecuta este script de nuevo después de 1-2 minutos"
fi

echo ""
echo "=========================================="
echo "🔧 COMANDOS ÚTILES PARA VERIFICAR"
echo "=========================================="
echo ""
echo "Ver estado del servicio:"
echo "  docker service ps $DASHBOARD_SERVICE"
echo ""
echo "Ver etiquetas del servicio:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq"
echo ""
echo "Ver logs de Traefik:"
echo "  docker service logs traefik --tail 50 | grep -i dashboard"
echo ""
echo "Probar acceso directo al contenedor:"
FIRST_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$FIRST_CONTAINER" ]; then
    echo "  docker exec $FIRST_CONTAINER curl -s http://127.0.0.1:3000/ | head -20"
fi
echo ""
