#!/bin/bash
# =====================================================
# APLICAR LABELS DE TRAEFIK AL SERVICIO DASHBOARD
# =====================================================
# Este script aplica las labels de Traefik directamente
# al servicio usando docker service update
# =====================================================

set -e

echo "=========================================="
echo "🔧 APLICANDO LABELS DE TRAEFIK"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"

# Verificar que el servicio existe
if ! docker service ls | grep -q "${SERVICE_NAME}"; then
    echo -e "${RED}❌ ERROR: El servicio ${SERVICE_NAME} no existe${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Servicio: ${SERVICE_NAME}${NC}"
echo -e "${BLUE}🌐 Dominio: ${DOMAIN}${NC}"
echo -e "${BLUE}🔌 Puerto: ${PORT}${NC}"
echo ""

# Obtener red de Traefik
echo "=========================================="
echo "1. OBTENIENDO RED DE TRAEFIK"
echo "=========================================="
echo ""

TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)

if [ -z "${TRAEFIK_SERVICE}" ]; then
    echo -e "${RED}❌ No se encontró servicio Traefik${NC}"
    exit 1
fi

TRAEFIK_NETWORK=$(docker service inspect "${TRAEFIK_SERVICE}" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}' 2>/dev/null | head -1)

if [ -z "${TRAEFIK_NETWORK}" ]; then
    echo -e "${YELLOW}⚠️  No se pudo obtener la red de Traefik automáticamente${NC}"
    echo "   Se intentará usar la red por defecto"
    TRAEFIK_NETWORK=""
else
    TRAEFIK_NETWORK_NAME=$(docker network inspect "${TRAEFIK_NETWORK}" --format '{{.Name}}' 2>/dev/null || echo "${TRAEFIK_NETWORK}")
    echo -e "${GREEN}✅ Red de Traefik: ${TRAEFIK_NETWORK_NAME}${NC}"
fi

echo ""

# Aplicar labels
echo "=========================================="
echo "2. APLICANDO LABELS DE TRAEFIK"
echo "=========================================="
echo ""

echo -e "${BLUE}🔄 Aplicando labels al servicio...${NC}"
echo ""

# Construir comando de actualización con labels
UPDATE_CMD="docker service update"

# Agregar labels
UPDATE_CMD="${UPDATE_CMD} --label-add 'traefik.enable=true'"
UPDATE_CMD="${UPDATE_CMD} --label-add 'traefik.http.routers.dashboard.rule=Host(\`${DOMAIN}\`)'"
UPDATE_CMD="${UPDATE_CMD} --label-add 'traefik.http.routers.dashboard.entrypoints=websecure'"
UPDATE_CMD="${UPDATE_CMD} --label-add 'traefik.http.routers.dashboard.tls.certresolver=letsencrypt'"
UPDATE_CMD="${UPDATE_CMD} --label-add 'traefik.http.services.dashboard.loadbalancer.server.port=${PORT}'"

# Agregar red si se encontró
if [ ! -z "${TRAEFIK_NETWORK}" ]; then
    UPDATE_CMD="${UPDATE_CMD} --network-add ${TRAEFIK_NETWORK}"
fi

UPDATE_CMD="${UPDATE_CMD} ${SERVICE_NAME}"

echo "📋 Comando a ejecutar:"
echo "   ${UPDATE_CMD}"
echo ""

# Ejecutar comando
eval "${UPDATE_CMD}"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Labels aplicadas correctamente${NC}"
else
    echo ""
    echo -e "${RED}❌ Error al aplicar las labels${NC}"
    exit 1
fi

echo ""

# Esperar a que el servicio se actualice
echo "=========================================="
echo "3. ESPERANDO ACTUALIZACIÓN"
echo "=========================================="
echo ""

echo -e "${YELLOW}⏳ Esperando 40 segundos para que el servicio se actualice...${NC}"
sleep 40

echo ""

# Verificar
echo "=========================================="
echo "4. VERIFICANDO LABELS APLICADAS"
echo "=========================================="
echo ""

TRAEFIK_LABELS=$(docker service inspect "${SERVICE_NAME}" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik || echo "")

if [ -z "${TRAEFIK_LABELS}" ]; then
    echo -e "${RED}❌ ERROR: Las labels NO se aplicaron${NC}"
    echo ""
    echo "   Puede ser que docker service update no soporte --label-add"
    echo "   o que haya un problema con la sintaxis"
    exit 1
else
    echo -e "${GREEN}✅ Labels de Traefik encontradas:${NC}"
    echo "${TRAEFIK_LABELS}" | sed 's/^/   /'
fi

echo ""

# Verificar en el contenedor
echo "=========================================="
echo "5. VERIFICANDO EN EL CONTENEDOR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ ! -z "${CONTAINER_ID}" ]; then
    echo -e "${GREEN}✅ Contenedor: ${CONTAINER_ID}${NC}"
    
    # Verificar red
    CONTAINER_NETWORKS=$(docker inspect "${CONTAINER_ID}" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null)
    
    if echo "${CONTAINER_NETWORKS}" | grep -q "${TRAEFIK_NETWORK_NAME}"; then
        echo -e "${GREEN}✅ Contenedor está en la red de Traefik${NC}"
    else
        echo -e "${YELLOW}⚠️  Contenedor puede no estar en la red de Traefik${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No se encontró contenedor (puede estar reiniciándose)${NC}"
fi

echo ""

# Resumen final
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Labels aplicadas:"
echo "   - traefik.enable=true"
echo "   - traefik.http.routers.dashboard.rule=Host(\`${DOMAIN}\`)"
echo "   - traefik.http.routers.dashboard.entrypoints=websecure"
echo "   - traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
echo "   - traefik.http.services.dashboard.loadbalancer.server.port=${PORT}"
echo ""
echo "🔄 Prueba acceder a: https://${DOMAIN}"
echo "   El error 404 debería estar resuelto"
echo ""
