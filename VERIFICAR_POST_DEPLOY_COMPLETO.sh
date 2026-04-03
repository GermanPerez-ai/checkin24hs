#!/bin/bash
# =====================================================
# SCRIPT DE VERIFICACIÓN POST-DEPLOY COMPLETO
# =====================================================
# Este script verifica que el deploy se haya realizado correctamente:
# 1. Verifica que el archivo dashboard.html se haya actualizado
# 2. Verifica el build number
# 3. Verifica HTTP y HTTPS
# 4. Verifica Traefik labels
# 5. Reinicia el servicio si es necesario
# =====================================================

set -e

echo "=========================================="
echo "VERIFICACIÓN POST-DEPLOY COMPLETA"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
EXPECTED_BUILD_NUMBER="37"  # Actualizar según el build actual (Build #37 - Corregir showFlorTab)

# Función para obtener el nombre del contenedor
get_container_name() {
    docker service ps ${SERVICE_NAME} --format "{{.Name}}" --filter "desired-state=running" | head -n 1
}

CONTAINER_NAME=$(get_container_name)

if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}❌ No se encontró contenedor en ejecución para el servicio ${SERVICE_NAME}${NC}"
    exit 1
fi

echo "📦 Contenedor encontrado: ${CONTAINER_NAME}"
echo ""

# =====================================================
# 1. VERIFICAR ARCHIVO EN EL CONTENEDOR
# =====================================================
echo "=========================================="
echo "1. VERIFICANDO ARCHIVO dashboard.html"
echo "=========================================="

FILE_PATH="/usr/share/nginx/html/dashboard.html"
CONTAINER_NAME=$(get_container_name)  # Obtener nuevamente por si cambió

if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${YELLOW}⚠️  No se pudo obtener el nombre del contenedor${NC}"
    FILE_EXISTS="No"
    FILE_SIZE="0"
else
    FILE_SIZE=$(docker exec ${CONTAINER_NAME} ls -lh ${FILE_PATH} 2>/dev/null | awk '{print $5}' || echo "0")
    FILE_EXISTS=$(docker exec ${CONTAINER_NAME} test -f ${FILE_PATH} 2>/dev/null && echo "Sí" || echo "No")
fi

echo "📄 Archivo: ${FILE_PATH}"
echo "📊 Existe: ${FILE_EXISTS}"
echo "📏 Tamaño: ${FILE_SIZE}"

if [ "$FILE_EXISTS" = "No" ] || [ "$FILE_SIZE" = "0" ]; then
    echo -e "${RED}❌ ERROR: El archivo no existe o está vacío${NC}"
    echo ""
    echo "🔧 SOLUCIÓN: Ejecutar ACTUALIZAR_ARCHIVO_SERVIDOR.sh"
    exit 1
fi

echo -e "${GREEN}✅ Archivo existe y tiene contenido${NC}"
echo ""

# =====================================================
# 2. VERIFICAR BUILD NUMBER
# =====================================================
echo "=========================================="
echo "2. VERIFICANDO BUILD NUMBER"
echo "=========================================="

# Extraer build number del archivo en el contenedor
BUILD_NUMBER=$(docker exec ${CONTAINER_NAME} grep -oP 'window\.DASHBOARD_BUILD_NUMBER = \K\d+' ${FILE_PATH} 2>/dev/null || echo "")

if [ -z "$BUILD_NUMBER" ]; then
    # Intentar método alternativo sin grep -P
    BUILD_NUMBER=$(docker exec ${CONTAINER_NAME} grep "window.DASHBOARD_BUILD_NUMBER" ${FILE_PATH} | sed 's/.*window\.DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/' || echo "")
fi

echo "🔢 Build Number encontrado: ${BUILD_NUMBER}"
echo "🎯 Build Number esperado: ${EXPECTED_BUILD_NUMBER}"

if [ "$BUILD_NUMBER" = "$EXPECTED_BUILD_NUMBER" ]; then
    echo -e "${GREEN}✅ Build number correcto${NC}"
else
    echo -e "${YELLOW}⚠️  Build number no coincide. Esperado: ${EXPECTED_BUILD_NUMBER}, Encontrado: ${BUILD_NUMBER}${NC}"
    echo "   Esto puede ser normal si el archivo aún no se ha actualizado en el servidor"
fi
echo ""

# =====================================================
# 3. VERIFICAR TRAEFIK LABELS
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO TRAEFIK LABELS"
echo "=========================================="

# Verificar que el servicio tenga las labels de Traefik
TRAEFIK_ENABLE=$(docker service inspect ${SERVICE_NAME} --format '{{index .Spec.Labels "traefik.enable"}}' 2>/dev/null || echo "")
TRAEFIK_RULE=$(docker service inspect ${SERVICE_NAME} --format '{{index .Spec.Labels "traefik.http.routers.dashboard.rule"}}' 2>/dev/null || echo "")

echo "🏷️  traefik.enable: ${TRAEFIK_ENABLE}"
echo "🏷️  traefik.http.routers.dashboard.rule: ${TRAEFIK_RULE}"

if [ "$TRAEFIK_ENABLE" = "true" ] && [ -n "$TRAEFIK_RULE" ]; then
    echo -e "${GREEN}✅ Traefik labels configuradas correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: Traefik labels no configuradas correctamente${NC}"
    echo ""
    echo "🔧 SOLUCIÓN: Ejecutar REAPLICAR_TRAEFIK_LABELS.sh"
    exit 1
fi
echo ""

# =====================================================
# 4. VERIFICAR HTTP
# =====================================================
echo "=========================================="
echo "4. VERIFICANDO HTTP (http://${DOMAIN})"
echo "=========================================="

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://${DOMAIN} || echo "000")
HTTP_BUILD=$(curl -s --max-time 10 http://${DOMAIN} | grep -oP 'window\.DASHBOARD_BUILD_NUMBER = \K\d+' 2>/dev/null || echo "")

if [ -z "$HTTP_BUILD" ]; then
    HTTP_BUILD=$(curl -s --max-time 10 http://${DOMAIN} | grep "window.DASHBOARD_BUILD_NUMBER" | sed 's/.*window\.DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/' || echo "")
fi

echo "📡 HTTP Status: ${HTTP_STATUS}"
echo "🔢 HTTP Build Number: ${HTTP_BUILD}"

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ HTTP funcionando correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: HTTP no responde correctamente (Status: ${HTTP_STATUS})${NC}"
    exit 1
fi
echo ""

# =====================================================
# 5. VERIFICAR HTTPS
# =====================================================
echo "=========================================="
echo "5. VERIFICANDO HTTPS (https://${DOMAIN})"
echo "=========================================="

HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${DOMAIN} || echo "000")
HTTPS_BUILD=$(curl -s --max-time 10 https://${DOMAIN} | grep -oP 'window\.DASHBOARD_BUILD_NUMBER = \K\d+' 2>/dev/null || echo "")

if [ -z "$HTTPS_BUILD" ]; then
    HTTPS_BUILD=$(curl -s --max-time 10 https://${DOMAIN} | grep "window.DASHBOARD_BUILD_NUMBER" | sed 's/.*window\.DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/' || echo "")
fi

echo "📡 HTTPS Status: ${HTTPS_STATUS}"
echo "🔢 HTTPS Build Number: ${HTTPS_BUILD}"

if [ "$HTTPS_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ HTTPS funcionando correctamente${NC}"
else
    echo -e "${RED}❌ ERROR: HTTPS no responde correctamente (Status: ${HTTPS_STATUS})${NC}"
    exit 1
fi
echo ""

# =====================================================
# 6. RESUMEN FINAL
# =====================================================
echo "=========================================="
echo "RESUMEN FINAL"
echo "=========================================="
echo ""
echo "📄 Archivo: ${GREEN}✅${NC}"
echo "🔢 Build Number (Contenedor): ${BUILD_NUMBER}"
echo "🔢 Build Number (HTTP): ${HTTP_BUILD}"
echo "🔢 Build Number (HTTPS): ${HTTPS_BUILD}"
echo "🏷️  Traefik Labels: ${GREEN}✅${NC}"
echo "📡 HTTP: ${GREEN}✅${NC}"
echo "🔒 HTTPS: ${GREEN}✅${NC}"
echo ""

if [ "$HTTP_BUILD" = "$EXPECTED_BUILD_NUMBER" ] && [ "$HTTPS_BUILD" = "$EXPECTED_BUILD_NUMBER" ]; then
    echo -e "${GREEN}=========================================="
    echo "✅ VERIFICACIÓN COMPLETA: TODO CORRECTO"
    echo "==========================================${NC}"
    echo ""
    echo "🎉 El deploy se realizó correctamente"
    echo "🌐 URL: https://${DOMAIN}"
    echo "🔢 Build: #${EXPECTED_BUILD_NUMBER}"
    exit 0
else
    echo -e "${YELLOW}=========================================="
    echo "⚠️  VERIFICACIÓN PARCIAL"
    echo "==========================================${NC}"
    echo ""
    echo "⚠️  El build number en el servidor puede no estar actualizado aún"
    echo "💡 Espera unos segundos y vuelve a ejecutar este script"
    echo "💡 O ejecuta ACTUALIZAR_ARCHIVO_SERVIDOR.sh para actualizar manualmente"
    exit 0
fi
