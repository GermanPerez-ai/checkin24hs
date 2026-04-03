#!/bin/bash
# =====================================================
# REAPLICAR TRAEFIK LABELS AL SERVICIO
# =====================================================
# Este script reaplica las labels de Traefik al servicio
# para asegurar que el routing funcione correctamente
# =====================================================

set -e

echo "=========================================="
echo "REAPLICANDO TRAEFIK LABELS"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "🔧 Servicio: ${SERVICE_NAME}"
echo "🌐 Dominio: ${DOMAIN}"
echo ""

# Verificar que el servicio existe
if ! docker service ls | grep -q "${SERVICE_NAME}"; then
    echo -e "${RED}❌ ERROR: El servicio ${SERVICE_NAME} no existe${NC}"
    exit 1
fi

# =====================================================
# REAPLICAR LABELS
# =====================================================
echo "=========================================="
echo "APLICANDO TRAEFIK LABELS"
echo "=========================================="

docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard.rule=Host(\`${DOMAIN}\`)" \
    --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard.service=dashboard" \
    --label-add "traefik.http.services.dashboard.loadbalancer.server.port=80" \
    ${SERVICE_NAME}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Labels aplicadas correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: No se pudieron aplicar las labels${NC}"
    exit 1
fi
echo ""

# =====================================================
# VERIFICAR LABELS
# =====================================================
echo "=========================================="
echo "VERIFICANDO LABELS"
echo "=========================================="

TRAEFIK_ENABLE=$(docker service inspect ${SERVICE_NAME} --format '{{index .Spec.Labels "traefik.enable"}}' 2>/dev/null || echo "")
TRAEFIK_RULE=$(docker service inspect ${SERVICE_NAME} --format '{{index .Spec.Labels "traefik.http.routers.dashboard.rule"}}' 2>/dev/null || echo "")

echo "🏷️  traefik.enable: ${TRAEFIK_ENABLE}"
echo "🏷️  traefik.http.routers.dashboard.rule: ${TRAEFIK_RULE}"

if [ "$TRAEFIK_ENABLE" = "true" ] && [ -n "$TRAEFIK_RULE" ]; then
    echo -e "${GREEN}✅ Labels verificadas correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: Las labels no se aplicaron correctamente${NC}"
    exit 1
fi
echo ""

# =====================================================
# ESPERAR A QUE EL SERVICIO ESTÉ LISTO
# =====================================================
echo "=========================================="
echo "ESPERANDO A QUE EL SERVICIO ESTÉ LISTO"
echo "=========================================="

echo "⏳ Esperando 10 segundos para que el servicio se actualice..."
sleep 10

# Verificar que el servicio esté corriendo
SERVICE_STATUS=$(docker service ps ${SERVICE_NAME} --format "{{.CurrentState}}" --filter "desired-state=running" | head -n 1)

if [ "$SERVICE_STATUS" = "Running" ]; then
    echo -e "${GREEN}✅ Servicio en ejecución${NC}"
else
    echo -e "${YELLOW}⚠️  Estado del servicio: ${SERVICE_STATUS}${NC}"
fi
echo ""

# =====================================================
# RESUMEN
# =====================================================
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo -e "${GREEN}✅ Traefik labels reaplicadas correctamente${NC}"
echo "🌐 URL: https://${DOMAIN}"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Esperar 30-60 segundos para que Traefik actualice la configuración"
echo "   2. Ejecutar: bash VERIFICAR_POST_DEPLOY_COMPLETO.sh"
echo ""
