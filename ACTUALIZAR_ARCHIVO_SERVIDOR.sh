#!/bin/bash
# =====================================================
# ACTUALIZAR ARCHIVO dashboard.html EN EL SERVIDOR
# =====================================================
# Este script descarga el archivo dashboard.html desde GitHub
# y lo copia al contenedor del servicio
# =====================================================

set -e

echo "=========================================="
echo "ACTUALIZANDO dashboard.html EN EL SERVIDOR"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
SERVICE_NAME="checkin24hs_dashboard"
GITHUB_RAW_URL="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"
TEMP_FILE="/tmp/dashboard.html"
<<<<<<< HEAD
CONTAINER_PATH="/usr/share/nginx/html/dashboard.html"
BACKUP_PATH="/tmp/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"

# Obtener nombre del contenedor
CONTAINER_NAME=$(docker service ps ${SERVICE_NAME} --format "{{.Name}}" --filter "desired-state=running" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}❌ No se encontró contenedor en ejecución${NC}"
    exit 1
fi

echo "📦 Contenedor: ${CONTAINER_NAME}"
=======
# Ruta del bind mount en el servidor (verificar con: docker service inspect checkin24hs_dashboard | grep -A 5 Mounts)
BIND_MOUNT_PATH="/root/checkin24hs/dashboard.html"
BACKUP_PATH="/tmp/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"

# Verificar que el servicio existe
if ! docker service ls | grep -q "${SERVICE_NAME}"; then
    echo -e "${RED}❌ ERROR: El servicio ${SERVICE_NAME} no existe${NC}"
    exit 1
fi

echo "🔧 Servicio: ${SERVICE_NAME}"
echo "📁 Bind Mount: ${BIND_MOUNT_PATH}"
>>>>>>> c0b28523105ec5714eeb7ca6b6de5bf4081624d9
echo ""

# =====================================================
# 1. CREAR BACKUP
# =====================================================
echo "=========================================="
echo "1. CREANDO BACKUP"
echo "=========================================="

if docker exec ${CONTAINER_NAME} test -f ${CONTAINER_PATH} 2>/dev/null; then
    docker cp ${CONTAINER_NAME}:${CONTAINER_PATH} ${BACKUP_PATH}
    echo -e "${GREEN}✅ Backup creado: ${BACKUP_PATH}${NC}"
else
    echo -e "${YELLOW}⚠️  No existe archivo previo para hacer backup${NC}"
fi
echo ""

# =====================================================
# 2. DESCARGAR ARCHIVO DESDE GITHUB
# =====================================================
echo "=========================================="
echo "2. DESCARGANDO DESDE GITHUB"
echo "=========================================="

echo "📥 Descargando desde: ${GITHUB_RAW_URL}"
curl -s -L -o ${TEMP_FILE} ${GITHUB_RAW_URL}

if [ ! -f "${TEMP_FILE}" ] || [ ! -s "${TEMP_FILE}" ]; then
    echo -e "${RED}❌ ERROR: No se pudo descargar el archivo${NC}"
    exit 1
fi

FILE_SIZE=$(ls -lh ${TEMP_FILE} | awk '{print $5}')
echo -e "${GREEN}✅ Archivo descargado: ${FILE_SIZE}${NC}"
echo ""

# =====================================================
# 3. VERIFICAR BUILD NUMBER
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO BUILD NUMBER"
echo "=========================================="

BUILD_NUMBER=$(grep -oP 'window\.DASHBOARD_BUILD_NUMBER = \K\d+' ${TEMP_FILE} 2>/dev/null || echo "")

if [ -z "$BUILD_NUMBER" ]; then
    BUILD_NUMBER=$(grep "window.DASHBOARD_BUILD_NUMBER" ${TEMP_FILE} | sed 's/.*window\.DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/' || echo "")
fi

if [ -n "$BUILD_NUMBER" ]; then
    echo -e "${GREEN}✅ Build Number: #${BUILD_NUMBER}${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudo extraer el build number${NC}"
fi
echo ""

# =====================================================
<<<<<<< HEAD
# 4. COPIAR AL CONTENEDOR
# =====================================================
echo "=========================================="
echo "4. COPIANDO AL CONTENEDOR"
echo "=========================================="

docker cp ${TEMP_FILE} ${CONTAINER_NAME}:${CONTAINER_PATH}

# Verificar que se copió correctamente
if docker exec ${CONTAINER_NAME} test -f ${CONTAINER_PATH} 2>/dev/null; then
    CONTAINER_SIZE=$(docker exec ${CONTAINER_NAME} ls -lh ${CONTAINER_PATH} | awk '{print $5}')
    echo -e "${GREEN}✅ Archivo copiado al contenedor: ${CONTAINER_SIZE}${NC}"
=======
# 4. COPIAR AL BIND MOUNT
# =====================================================
echo "=========================================="
echo "4. COPIANDO AL BIND MOUNT"
echo "=========================================="

# Asegurar que el directorio existe
mkdir -p $(dirname ${BIND_MOUNT_PATH})

# Copiar el archivo al bind mount
cp ${TEMP_FILE} ${BIND_MOUNT_PATH}

# Verificar que se copió correctamente
if [ -f "${BIND_MOUNT_PATH}" ]; then
    FILE_SIZE=$(ls -lh ${BIND_MOUNT_PATH} | awk '{print $5}')
    echo -e "${GREEN}✅ Archivo copiado al bind mount: ${FILE_SIZE}${NC}"
    echo "   Ruta: ${BIND_MOUNT_PATH}"
>>>>>>> c0b28523105ec5714eeb7ca6b6de5bf4081624d9
else
    echo -e "${RED}❌ ERROR: No se pudo copiar el archivo${NC}"
    exit 1
fi
echo ""

# =====================================================
<<<<<<< HEAD
# 5. VERIFICAR EN EL CONTENEDOR
# =====================================================
echo "=========================================="
echo "5. VERIFICANDO EN EL CONTENEDOR"
echo "=========================================="

CONTAINER_BUILD=$(docker exec ${CONTAINER_NAME} grep -oP 'window\.DASHBOARD_BUILD_NUMBER = \K\d+' ${CONTAINER_PATH} 2>/dev/null || echo "")

if [ -z "$CONTAINER_BUILD" ]; then
    CONTAINER_BUILD=$(docker exec ${CONTAINER_NAME} grep "window.DASHBOARD_BUILD_NUMBER" ${CONTAINER_PATH} | sed 's/.*window\.DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/' || echo "")
fi

if [ "$CONTAINER_BUILD" = "$BUILD_NUMBER" ]; then
    echo -e "${GREEN}✅ Build number verificado en el contenedor: #${CONTAINER_BUILD}${NC}"
else
    echo -e "${YELLOW}⚠️  Build number no coincide${NC}"
=======
# 5. VERIFICAR EN EL ARCHIVO
# =====================================================
echo "=========================================="
echo "5. VERIFICANDO EN EL ARCHIVO"
echo "=========================================="

FILE_BUILD=$(grep -oP 'window\.DASHBOARD_BUILD_NUMBER = \K\d+' ${BIND_MOUNT_PATH} 2>/dev/null || echo "")

if [ -z "$FILE_BUILD" ]; then
    FILE_BUILD=$(grep "window.DASHBOARD_BUILD_NUMBER" ${BIND_MOUNT_PATH} 2>/dev/null | sed 's/.*window\.DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/' || echo "")
fi

if [ "$FILE_BUILD" = "$BUILD_NUMBER" ]; then
    echo -e "${GREEN}✅ Build number verificado en el archivo: #${FILE_BUILD}${NC}"
else
    echo -e "${YELLOW}⚠️  Build number no coincide${NC}"
    echo "   Esperado: #${BUILD_NUMBER}, Encontrado: #${FILE_BUILD}"
>>>>>>> c0b28523105ec5714eeb7ca6b6de5bf4081624d9
fi
echo ""

# =====================================================
# 6. LIMPIAR ARCHIVO TEMPORAL
# =====================================================
rm -f ${TEMP_FILE}
echo -e "${GREEN}✅ Archivo temporal eliminado${NC}"
echo ""

# =====================================================
# RESUMEN
# =====================================================
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo -e "${GREEN}✅ Archivo actualizado correctamente${NC}"
<<<<<<< HEAD
echo "📦 Contenedor: ${CONTAINER_NAME}"
echo "🔢 Build Number: #${BUILD_NUMBER}"
echo "💾 Backup: ${BACKUP_PATH}"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Ejecutar: bash VERIFICAR_POST_DEPLOY_COMPLETO.sh"
echo "   2. Si hay problemas con Traefik, ejecutar: bash REAPLICAR_TRAEFIK_LABELS.sh"
=======
echo "📁 Ruta: ${BIND_MOUNT_PATH}"
echo "🔢 Build Number: #${BUILD_NUMBER}"
echo "💾 Backup: ${BACKUP_PATH}"
echo ""
echo "💡 Nota: El servicio usará automáticamente el nuevo archivo gracias al bind mount"
echo "💡 Próximos pasos:"
echo "   1. Esperar unos segundos para que el servicio detecte el cambio"
echo "   2. Verificar: curl -s https://dashboard.checkin24hs.com | grep 'DASHBOARD_BUILD_NUMBER'"
echo "   3. Si hay problemas con Traefik, ejecutar: bash REAPLICAR_TRAEFIK_LABELS.sh"
>>>>>>> c0b28523105ec5714eeb7ca6b6de5bf4081624d9
echo ""
