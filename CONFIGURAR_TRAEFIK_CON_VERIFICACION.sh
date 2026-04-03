#!/bin/bash
# Script completo para configurar Traefik con verificación exhaustiva

echo "=========================================="
echo "🔧 Configurando Traefik - Con Verificación Completa"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar comando
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 no está instalado${NC}"
        return 1
    fi
    return 0
}

# Verificar comandos necesarios
echo "0️⃣ Verificando herramientas necesarias..."
check_command docker || exit 1
check_command jq || echo -e "${YELLOW}⚠️ jq no está instalado (algunas verificaciones pueden fallar)${NC}"
check_command curl || echo -e "${YELLOW}⚠️ curl no está instalado (no se podrá verificar acceso HTTP)${NC}"
echo ""

# 1. Verificar estado del servicio
echo "1️⃣ Verificando estado del servicio..."
SERVICE_STATUS=$(docker service ls | grep "$DASHBOARD_SERVICE" | awk '{print $4}')

if [ -z "$SERVICE_STATUS" ]; then
    echo -e "${RED}❌ El servicio NO está corriendo${NC}"
    echo "Servicios disponibles:"
    docker service ls | grep "checkin24hs"
    exit 1
fi

echo -e "${GREEN}✅ Servicio está: $SERVICE_STATUS${NC}"
echo ""

# 2. Verificar contenedor y acceso directo
echo "2️⃣ Verificando contenedor y acceso directo..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}❌ No se encontró contenedor del dashboard${NC}"
    echo "Contenedores activos:"
    docker ps --filter "name=dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo "Probando acceso directo al servidor..."

# Verificar que el servidor responde
SERVER_RESPONSE=$(docker exec "$CONTAINER_ID" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4, timeout: 5000}, (res) => {
    console.log('Status:', res.statusCode);
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ El servidor NO responde correctamente${NC}"
    echo "Respuesta: $SERVER_RESPONSE"
    echo ""
    echo "Verificando logs del contenedor..."
    docker logs "$CONTAINER_ID" --tail 20
    exit 1
fi

echo -e "${GREEN}✅ El servidor responde correctamente${NC}"
echo ""

# 3. Verificar red del servicio
echo "3️⃣ Verificando red del servicio..."
SERVICE_NETWORKS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)

if echo "$SERVICE_NETWORKS" | grep -q "$NETWORK"; then
    echo -e "${GREEN}✅ El servicio está en la red $NETWORK${NC}"
else
    echo -e "${YELLOW}⚠️ El servicio NO está en la red $NETWORK${NC}"
    echo "Verificando si la red existe..."
    
    if docker network ls | grep -q "$NETWORK"; then
        echo "Agregando el servicio a la red $NETWORK..."
        if docker service update --network-add "$NETWORK" "$DASHBOARD_SERVICE" 2>/dev/null; then
            echo -e "${GREEN}✅ Servicio agregado a la red${NC}"
            echo "Esperando 10 segundos para que se aplique..."
            sleep 10
        else
            echo -e "${YELLOW}⚠️ El servicio ya está en la red o hubo un error${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ La red $NETWORK no existe, se creará automáticamente${NC}"
        docker service update --network-add "$NETWORK" "$DASHBOARD_SERVICE" 2>/dev/null
        echo "Esperando 10 segundos..."
        sleep 10
    fi
fi

echo ""

# 4. Eliminar etiquetas anteriores
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

# 5. Aplicar nuevas etiquetas
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
    echo -e "${GREEN}✅ Etiquetas aplicadas correctamente${NC}"
else
    echo -e "${RED}❌ Error al aplicar etiquetas${NC}"
    exit 1
fi

echo ""
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 7. Verificar etiquetas aplicadas
echo ""
echo "7️⃣ Verificando etiquetas aplicadas..."
SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)

if [ -z "$SERVICE_JSON" ]; then
    echo -e "${RED}❌ No se pudieron obtener las etiquetas del servicio${NC}"
else
    if command -v jq &> /dev/null; then
        TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)
    else
        TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | grep -o '"traefik[^"]*":"[^"]*"' | sed 's/"//g' | sed 's/:/=/' 2>/dev/null)
    fi
    
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo -e "${RED}❌ Las etiquetas NO se aplicaron${NC}"
        echo ""
        echo -e "${YELLOW}⚠️ EasyPanel está sobrescribiendo las etiquetas${NC}"
        echo ""
        echo -e "${GREEN}✅ SOLUCIÓN: Configurar dominio desde EasyPanel${NC}"
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
        echo -e "${GREEN}✅ Etiquetas Traefik aplicadas:${NC}"
        echo "$TRAEFIK_LABELS" | head -15 | while read line; do
            echo "   $line"
        done
    fi
fi

echo ""

# 8. Verificar acceso a través de Traefik
echo "8️⃣ Verificando acceso a través de Traefik..."
if command -v curl &> /dev/null; then
    echo "Probando: https://$DOMAIN"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN" 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Dashboard accesible a través de Traefik (HTTP 200)${NC}"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo -e "${YELLOW}⚠️ No se pudo conectar (posible problema de DNS o Traefik)${NC}"
        echo "   Verifica que el DNS apunte a este servidor"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo -e "${RED}❌ Error 404 - Traefik no está enrutando correctamente${NC}"
        echo "   Verifica las etiquetas Traefik del servicio"
    elif [ "$HTTP_CODE" = "502" ] || [ "$HTTP_CODE" = "503" ]; then
        echo -e "${YELLOW}⚠️ Error $HTTP_CODE - Servicio no disponible${NC}"
        echo "   El servicio puede estar iniciando, espera unos minutos"
    else
        echo -e "${YELLOW}⚠️ Código HTTP: $HTTP_CODE${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ curl no está disponible${NC}"
    echo "   Prueba manualmente: https://$DOMAIN"
fi

echo ""

# 9. Verificar logs de Traefik
echo "9️⃣ Verificando logs de Traefik..."
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $2}' | head -1)

if [ ! -z "$TRAEFIK_SERVICE" ]; then
    echo "Buscando errores relacionados con dashboard..."
    TRAEFIK_LOGS=$(docker service logs "$TRAEFIK_SERVICE" --tail 50 2>&1 | grep -iE "(dashboard|$ROUTER_NAME|error|router.*cannot)" | tail -10)
    
    if [ -z "$TRAEFIK_LOGS" ]; then
        echo -e "${GREEN}✅ No hay errores relevantes en Traefik${NC}"
    else
        echo -e "${YELLOW}⚠️ Logs de Traefik:${NC}"
        echo "$TRAEFIK_LOGS" | while read line; do
            echo "   $line"
        done
    fi
else
    echo -e "${YELLOW}⚠️ No se encontró el servicio Traefik${NC}"
fi

echo ""

# 10. Verificar estado de Traefik
echo "🔟 Verificando estado de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${GREEN}✅ Traefik está corriendo (contenedor: $TRAEFIK_CONTAINER)${NC}"
    
    # Verificar que Traefik está escuchando en los puertos correctos
    TRAEFIK_PORTS=$(docker port "$TRAEFIK_CONTAINER" 2>/dev/null | grep -E "(80|443)" || echo "")
    if [ ! -z "$TRAEFIK_PORTS" ]; then
        echo "   Puertos expuestos:"
        echo "$TRAEFIK_PORTS" | while read line; do
            echo "   $line"
        done
    fi
else
    echo -e "${RED}❌ Traefik NO está corriendo${NC}"
fi

echo ""

# 11. Verificar red easypanel
echo "1️⃣1️⃣ Verificando red easypanel..."
if docker network ls | grep -q "$NETWORK"; then
    echo -e "${GREEN}✅ Red $NETWORK existe${NC}"
    
    # Verificar que el dashboard está en la red
    NETWORK_CONTAINERS=$(docker network inspect "$NETWORK" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
    if echo "$NETWORK_CONTAINERS" | grep -q "dashboard"; then
        echo -e "${GREEN}✅ Dashboard está en la red $NETWORK${NC}"
    else
        echo -e "${YELLOW}⚠️ Dashboard NO está visible en la red $NETWORK${NC}"
        echo "   Esto puede ser normal si el servicio está en Docker Swarm"
    fi
else
    echo -e "${RED}❌ Red $NETWORK NO existe${NC}"
fi

echo ""

# Resumen final
echo "=========================================="
echo "📋 RESUMEN FINAL"
echo "=========================================="
echo ""

if [ ! -z "$TRAEFIK_LABELS" ]; then
    echo -e "${GREEN}✅ Etiquetas Traefik aplicadas correctamente${NC}"
    echo ""
    echo "⏳ Espera 1-2 minutos y prueba:"
    echo "   https://$DOMAIN"
    echo ""
    echo "Si aún no funciona:"
    echo "   1. Verifica el DNS: $DOMAIN debe apuntar a este servidor"
    echo "   2. Espera 2-3 minutos para que Traefik procese los cambios"
    echo "   3. Verifica los logs: docker service logs traefik --tail 50"
else
    echo -e "${RED}❌ Las etiquetas NO se aplicaron${NC}"
    echo ""
    echo -e "${GREEN}✅ SOLUCIÓN: Configura el dominio desde EasyPanel${NC}"
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
fi

echo ""
echo "Para verificar etiquetas manualmente:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq"
echo ""
echo "Para ver logs de Traefik:"
echo "  docker service logs traefik --tail 50"
echo ""
