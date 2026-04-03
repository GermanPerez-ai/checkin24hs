#!/bin/bash
# =====================================================
# VERIFICAR QUE TODOS LOS ARCHIVOS NECESARIOS ESTÉN ACTUALIZADOS
# =====================================================
# Este script verifica que dashboard.html y supabase-client.js
# estén actualizados en el servidor (bind mount)
# =====================================================

set -e

echo "=========================================="
echo "🔍 VERIFICANDO ARCHIVOS EN EL SERVIDOR"
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
DASHBOARD_FILE="${BIND_MOUNT_DIR}/dashboard.html"
SUPABASE_FILE="${BIND_MOUNT_DIR}/supabase-client.js"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main"

# Verificar que el servicio existe
if ! docker service ls | grep -q "${SERVICE_NAME}"; then
    echo -e "${RED}❌ ERROR: El servicio ${SERVICE_NAME} no existe${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Servicio: ${SERVICE_NAME}${NC}"
echo ""

# =====================================================
# 1. VERIFICAR ESTRUCTURA DE DIRECTORIOS
# =====================================================
echo "=========================================="
echo "1. VERIFICANDO ESTRUCTURA DE DIRECTORIOS"
echo "=========================================="
echo ""

if [ ! -d "${BIND_MOUNT_DIR}" ]; then
    echo -e "${YELLOW}⚠️  Directorio ${BIND_MOUNT_DIR} no existe, creándolo...${NC}"
    mkdir -p "${BIND_MOUNT_DIR}"
    echo -e "${GREEN}✅ Directorio creado${NC}"
else
    echo -e "${GREEN}✅ Directorio ${BIND_MOUNT_DIR} existe${NC}"
fi
echo ""

# =====================================================
# 2. VERIFICAR dashboard.html
# =====================================================
echo "=========================================="
echo "2. VERIFICANDO dashboard.html"
echo "=========================================="
echo ""

DASHBOARD_NEEDS_UPDATE=false

if [ ! -f "${DASHBOARD_FILE}" ]; then
    echo -e "${YELLOW}⚠️  dashboard.html no existe en ${DASHBOARD_FILE}${NC}"
    DASHBOARD_NEEDS_UPDATE=true
else
    echo -e "${GREEN}✅ dashboard.html existe${NC}"
    
    # Verificar Build Number
    CURRENT_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "${DASHBOARD_FILE}" 2>/dev/null | head -1 || echo "0")
    echo "   Build Number actual: #${CURRENT_BUILD}"
    
    # Descargar versión de GitHub para comparar
    echo "   Descargando versión de GitHub para comparar..."
    TEMP_DASHBOARD=$(mktemp)
    if curl -s -L "${GITHUB_REPO}/dashboard.html" -o "${TEMP_DASHBOARD}" 2>/dev/null; then
        GITHUB_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "${TEMP_DASHBOARD}" 2>/dev/null | head -1 || echo "0")
        echo "   Build Number en GitHub: #${GITHUB_BUILD}"
        
        if [ "${CURRENT_BUILD}" -lt "${GITHUB_BUILD}" ]; then
            echo -e "${YELLOW}⚠️  dashboard.html está desactualizado (local: #${CURRENT_BUILD}, GitHub: #${GITHUB_BUILD})${NC}"
            DASHBOARD_NEEDS_UPDATE=true
        else
            echo -e "${GREEN}✅ dashboard.html está actualizado${NC}"
        fi
        
        # Verificar que tiene la función viewQuote async
        if grep -q "async function viewQuote" "${DASHBOARD_FILE}"; then
            echo -e "${GREEN}✅ viewQuote es async (corrección aplicada)${NC}"
        else
            echo -e "${YELLOW}⚠️  viewQuote no es async, necesita actualización${NC}"
            DASHBOARD_NEEDS_UPDATE=true
        fi
        
        rm -f "${TEMP_DASHBOARD}"
    else
        echo -e "${YELLOW}⚠️  No se pudo descargar versión de GitHub para comparar${NC}"
    fi
fi

echo ""

# =====================================================
# 3. VERIFICAR supabase-client.js
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO supabase-client.js"
echo "=========================================="
echo ""

SUPABASE_NEEDS_UPDATE=false

if [ ! -f "${SUPABASE_FILE}" ]; then
    echo -e "${YELLOW}⚠️  supabase-client.js no existe en ${SUPABASE_FILE}${NC}"
    SUPABASE_NEEDS_UPDATE=true
else
    echo -e "${GREEN}✅ supabase-client.js existe${NC}"
    
    # Verificar que tiene la corrección de getQuotes
    if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}"; then
        echo -e "${GREEN}✅ getQuotes tiene la corrección aplicada${NC}"
    else
        echo -e "${YELLOW}⚠️  getQuotes no tiene la corrección, necesita actualización${NC}"
        SUPABASE_NEEDS_UPDATE=true
    fi
    
    # Verificar manejo de QuotaExceededError
    if grep -q "QuotaExceededError" "${SUPABASE_FILE}"; then
        echo -e "${GREEN}✅ Manejo de QuotaExceededError presente${NC}"
    else
        echo -e "${YELLOW}⚠️  Falta manejo de QuotaExceededError${NC}"
        SUPABASE_NEEDS_UPDATE=true
    fi
fi

echo ""

# =====================================================
# 4. ACTUALIZAR ARCHIVOS SI ES NECESARIO
# =====================================================
if [ "${DASHBOARD_NEEDS_UPDATE}" = true ] || [ "${SUPABASE_NEEDS_UPDATE}" = true ]; then
    echo "=========================================="
    echo "4. ACTUALIZANDO ARCHIVOS"
    echo "=========================================="
    echo ""
    
    # Actualizar dashboard.html
    if [ "${DASHBOARD_NEEDS_UPDATE}" = true ]; then
        echo -e "${BLUE}📥 Descargando dashboard.html desde GitHub...${NC}"
        if curl -s -L "${GITHUB_REPO}/dashboard.html" -o "${DASHBOARD_FILE}"; then
            echo -e "${GREEN}✅ dashboard.html actualizado${NC}"
            
            # Verificar Build Number después de actualizar
            NEW_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "${DASHBOARD_FILE}" 2>/dev/null | head -1 || echo "0")
            echo "   Nuevo Build Number: #${NEW_BUILD}"
        else
            echo -e "${RED}❌ Error al descargar dashboard.html${NC}"
        fi
        echo ""
    fi
    
    # Actualizar supabase-client.js
    if [ "${SUPABASE_NEEDS_UPDATE}" = true ]; then
        echo -e "${BLUE}📥 Descargando supabase-client.js desde GitHub...${NC}"
        if curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${SUPABASE_FILE}"; then
            echo -e "${GREEN}✅ supabase-client.js actualizado${NC}"
            
            # Verificar que tiene la corrección
            if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}"; then
                echo -e "${GREEN}✅ Corrección verificada${NC}"
            fi
        else
            echo -e "${RED}❌ Error al descargar supabase-client.js${NC}"
        fi
        echo ""
    fi
    
    # Reiniciar servicio para aplicar cambios
    echo "=========================================="
    echo "5. REINICIANDO SERVICIO"
    echo "=========================================="
    echo ""
    
    echo -e "${BLUE}🔄 Reiniciando servicio para aplicar cambios...${NC}"
    docker service update --force "${SERVICE_NAME}"
    
    echo ""
    echo -e "${YELLOW}⏳ Esperando 30 segundos para que el servicio se reinicie...${NC}"
    sleep 30
    
    echo -e "${GREEN}✅ Servicio reiniciado${NC}"
    echo ""
else
    echo "=========================================="
    echo "4. RESUMEN"
    echo "=========================================="
    echo ""
    echo -e "${GREEN}✅ Todos los archivos están actualizados${NC}"
    echo ""
fi

# =====================================================
# 5. VERIFICAR ARCHIVOS EN EL CONTENEDOR
# =====================================================
echo "=========================================="
echo "6. VERIFICANDO ARCHIVOS EN EL CONTENEDOR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo -e "${YELLOW}⚠️  No se encontró contenedor en ejecución${NC}"
    echo "   El servicio puede estar reiniciándose..."
else
    echo -e "${GREEN}✅ Contenedor encontrado: ${CONTAINER_ID}${NC}"
    echo ""
    
    # Verificar dashboard.html en el contenedor
    echo "📋 Verificando dashboard.html en el contenedor..."
    if docker exec "${CONTAINER_ID}" test -f /app/dashboard.html 2>/dev/null; then
        CONTAINER_BUILD=$(docker exec "${CONTAINER_ID}" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1 || echo "0")
        echo -e "${GREEN}✅ dashboard.html existe en el contenedor (Build #${CONTAINER_BUILD})${NC}"
        
        # Verificar que viewQuote es async
        if docker exec "${CONTAINER_ID}" grep -q "async function viewQuote" /app/dashboard.html 2>/dev/null; then
            echo -e "${GREEN}✅ viewQuote es async en el contenedor${NC}"
        else
            echo -e "${RED}❌ viewQuote NO es async en el contenedor${NC}"
        fi
    else
        echo -e "${RED}❌ dashboard.html NO existe en el contenedor${NC}"
    fi
    echo ""
    
    # Verificar supabase-client.js en el contenedor
    echo "📋 Verificando supabase-client.js en el contenedor..."
    if docker exec "${CONTAINER_ID}" test -f /app/supabase-client.js 2>/dev/null; then
        echo -e "${GREEN}✅ supabase-client.js existe en el contenedor${NC}"
        
        # Verificar corrección
        if docker exec "${CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js 2>/dev/null; then
            echo -e "${GREEN}✅ Corrección de getQuotes presente en el contenedor${NC}"
        else
            echo -e "${RED}❌ Corrección de getQuotes NO presente en el contenedor${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  supabase-client.js NO existe en el contenedor (puede estar en otra ruta)${NC}"
    fi
    echo ""
fi

# =====================================================
# RESUMEN FINAL
# =====================================================
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - dashboard.html: $([ -f "${DASHBOARD_FILE}" ] && echo "✅ Existe" || echo "❌ No existe")"
echo "   - supabase-client.js: $([ -f "${SUPABASE_FILE}" ] && echo "✅ Existe" || echo "❌ No existe")"
echo ""
echo "🔄 Si se actualizaron archivos, recarga la página del dashboard (F5)"
echo "   y prueba hacer clic en 'Ver' una cotización"
echo ""
