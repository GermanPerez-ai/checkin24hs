#!/bin/bash
# =====================================================
# ACTUALIZAR supabase-client.js EN EL CONTENEDOR
# =====================================================
# Este script actualiza supabase-client.js en el contenedor
# Si está montado como bind mount, actualiza el archivo del host
# Si no está montado, copia directamente al contenedor
# =====================================================

set -e

echo "=========================================="
echo "🔄 ACTUALIZANDO supabase-client.js"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SERVICE_NAME="checkin24hs_dashboard"
BIND_MOUNT_DIR="/root/checkin24hs"
SUPABASE_FILE="${BIND_MOUNT_DIR}/supabase-client.js"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main"
CONTAINER_PATH="/app/supabase-client.js"

# Verificar que el servicio existe
if ! docker service ls | grep -q "${SERVICE_NAME}"; then
    echo -e "${RED}❌ ERROR: El servicio ${SERVICE_NAME} no existe${NC}"
    exit 1
fi

# Obtener contenedor
CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo -e "${RED}❌ No se encontró contenedor en ejecución${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Contenedor: ${CONTAINER_ID}${NC}"
echo ""

# Verificar si supabase-client.js está montado como bind mount
echo "=========================================="
echo "1. VERIFICANDO MOUNTS"
echo "=========================================="
echo ""

IS_MOUNTED=false
MOUNT_SOURCE=""

# Verificar mounts del contenedor
MOUNT_INFO=$(docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{.Type}}|{{.Source}}|{{.Destination}}{{"\n"}}{{end}}' | grep "supabase-client.js" || true)

if [ ! -z "${MOUNT_INFO}" ]; then
    IS_MOUNTED=true
    MOUNT_SOURCE=$(echo "${MOUNT_INFO}" | cut -d'|' -f2)
    echo -e "${GREEN}✅ supabase-client.js está montado como bind mount${NC}"
    echo "   Origen: ${MOUNT_SOURCE}"
    echo "   Destino: ${CONTAINER_PATH}"
else
    echo -e "${YELLOW}⚠️  supabase-client.js NO está montado como bind mount${NC}"
    echo "   Se copiará directamente al contenedor"
fi

echo ""

# =====================================================
# 2. ACTUALIZAR ARCHIVO
# =====================================================
echo "=========================================="
echo "2. ACTUALIZANDO ARCHIVO"
echo "=========================================="
echo ""

if [ "${IS_MOUNTED}" = true ]; then
    # Si está montado, actualizar el archivo del host
    echo -e "${BLUE}📥 Descargando supabase-client.js desde GitHub...${NC}"
    
    if curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${MOUNT_SOURCE}"; then
        echo -e "${GREEN}✅ Archivo actualizado en: ${MOUNT_SOURCE}${NC}"
        
        # Verificar que tiene la corrección
        if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${MOUNT_SOURCE}"; then
            echo -e "${GREEN}✅ Corrección verificada${NC}"
        else
            echo -e "${RED}❌ ERROR: La corrección no está presente${NC}"
        fi
    else
        echo -e "${RED}❌ Error al descargar el archivo${NC}"
        exit 1
    fi
else
    # Si no está montado, descargar y copiar al contenedor
    TEMP_FILE=$(mktemp)
    
    echo -e "${BLUE}📥 Descargando supabase-client.js desde GitHub...${NC}"
    if curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${TEMP_FILE}"; then
        echo -e "${GREEN}✅ Archivo descargado${NC}"
        
        # Verificar que tiene la corrección
        if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${TEMP_FILE}"; then
            echo -e "${GREEN}✅ Corrección verificada${NC}"
        else
            echo -e "${RED}❌ ERROR: La corrección no está presente${NC}"
            rm -f "${TEMP_FILE}"
            exit 1
        fi
        
        # Hacer backup del archivo actual
        echo ""
        echo "💾 Haciendo backup del archivo actual..."
        docker exec "${CONTAINER_ID}" cp "${CONTAINER_PATH}" "${CONTAINER_PATH}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || echo "   (No se pudo hacer backup, continuando...)"
        
        # Copiar al contenedor
        echo ""
        echo "📋 Copiando archivo al contenedor..."
        docker cp "${TEMP_FILE}" "${CONTAINER_ID}:${CONTAINER_PATH}"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Archivo copiado al contenedor${NC}"
        else
            echo -e "${RED}❌ Error al copiar el archivo${NC}"
            rm -f "${TEMP_FILE}"
            exit 1
        fi
        
        rm -f "${TEMP_FILE}"
    else
        echo -e "${RED}❌ Error al descargar el archivo${NC}"
        exit 1
    fi
fi

echo ""

# =====================================================
# 3. VERIFICAR EN EL CONTENEDOR
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO EN EL CONTENEDOR"
echo "=========================================="
echo ""

# Esperar un momento para que el archivo se actualice
sleep 2

# Verificar que el archivo existe
if docker exec "${CONTAINER_ID}" test -f "${CONTAINER_PATH}" 2>/dev/null; then
    echo -e "${GREEN}✅ Archivo existe en el contenedor${NC}"
    
    # Verificar que tiene la corrección
    if docker exec "${CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${CONTAINER_PATH}" 2>/dev/null; then
        echo -e "${GREEN}✅ Corrección presente en el contenedor${NC}"
    else
        echo -e "${RED}❌ ERROR: La corrección NO está presente en el contenedor${NC}"
        echo "   Esto puede indicar que el archivo no se actualizó correctamente"
    fi
else
    echo -e "${RED}❌ ERROR: El archivo NO existe en el contenedor${NC}"
fi

echo ""

# =====================================================
# 4. REINICIAR SERVICIO (si no está montado)
# =====================================================
if [ "${IS_MOUNTED}" = false ]; then
    echo "=========================================="
    echo "4. REINICIANDO SERVICIO"
    echo "=========================================="
    echo ""
    
    echo -e "${YELLOW}⚠️  Como el archivo NO está montado, los cambios se perderán al reiniciar el contenedor${NC}"
    echo "   Se recomienda configurar un bind mount para supabase-client.js"
    echo ""
    echo -e "${BLUE}🔄 Reiniciando servicio para aplicar cambios...${NC}"
    docker service update --force "${SERVICE_NAME}"
    
    echo ""
    echo -e "${YELLOW}⏳ Esperando 30 segundos para que el servicio se reinicie...${NC}"
    sleep 30
    
    echo -e "${GREEN}✅ Servicio reiniciado${NC}"
    echo ""
fi

# =====================================================
# RESUMEN FINAL
# =====================================================
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Archivo actualizado: ✅"
if [ "${IS_MOUNTED}" = true ]; then
    echo "   - Tipo: Bind mount (persistente)"
else
    echo "   - Tipo: Copia directa (temporal - se perderá al reiniciar)"
    echo "   - ⚠️  RECOMENDACIÓN: Configurar bind mount para supabase-client.js"
fi
echo ""
echo "🔄 Recarga la página del dashboard (F5) y prueba hacer clic en 'Ver' una cotización"
echo ""
