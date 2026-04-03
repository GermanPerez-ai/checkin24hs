#!/bin/bash
# =====================================================
# APLICAR BIND MOUNT DE supabase-client.js
# =====================================================
# Este script verifica y aplica el bind mount
# reiniciando el servicio si es necesario
# =====================================================

set -e

echo "=========================================="
echo "🔄 APLICANDO BIND MOUNT DE supabase-client.js"
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
SUPABASE_FILE="/root/checkin24hs/supabase-client.js"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main"

# =====================================================
# 1. VERIFICAR ARCHIVO EN SERVIDOR
# =====================================================
echo "=========================================="
echo "1. VERIFICANDO ARCHIVO EN SERVIDOR"
echo "=========================================="
echo ""

if [ ! -f "${SUPABASE_FILE}" ]; then
    echo -e "${YELLOW}⚠️  Archivo no existe, descargándolo desde GitHub...${NC}"
    curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${SUPABASE_FILE}"
    chmod 644 "${SUPABASE_FILE}"
    echo -e "${GREEN}✅ Archivo descargado${NC}"
else
    echo -e "${GREEN}✅ Archivo existe: ${SUPABASE_FILE}${NC}"
fi

# Verificar corrección
if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}"; then
    echo -e "${GREEN}✅ Corrección presente en el archivo del servidor${NC}"
else
    echo -e "${YELLOW}⚠️  Corrección NO presente, actualizando desde GitHub...${NC}"
    curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${SUPABASE_FILE}"
    chmod 644 "${SUPABASE_FILE}"
    
    if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}"; then
        echo -e "${GREEN}✅ Archivo actualizado con corrección${NC}"
    else
        echo -e "${RED}❌ ERROR: No se pudo actualizar el archivo${NC}"
        exit 1
    fi
fi

echo ""

# =====================================================
# 2. VERIFICAR MOUNT EN CONTENEDOR
# =====================================================
echo "=========================================="
echo "2. VERIFICANDO MOUNT EN CONTENEDOR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo -e "${RED}❌ No se encontró contenedor en ejecución${NC}"
    echo -e "${YELLOW}⚠️  Reiniciando servicio...${NC}"
    docker service update --force "${SERVICE_NAME}"
    echo -e "${YELLOW}⏳ Esperando 30 segundos para que el servicio se reinicie...${NC}"
    sleep 30
    CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)
    
    if [ -z "${CONTAINER_ID}" ]; then
        echo -e "${RED}❌ ERROR: No se pudo encontrar el contenedor después del reinicio${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Contenedor encontrado: ${CONTAINER_ID}${NC}"

# Verificar mount
MOUNT_INFO=$(docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}|{{.Destination}}{{"\n"}}{{end}}{{end}}' | grep "supabase-client.js" || true)

if [ -z "${MOUNT_INFO}" ]; then
    echo -e "${RED}❌ ERROR: El bind mount NO está configurado en el contenedor${NC}"
    echo -e "${YELLOW}⚠️  Asegúrate de haber configurado el bind mount en EasyPanel${NC}"
    echo ""
    echo "   Source: ${SUPABASE_FILE}"
    echo "   Destination: /app/supabase-client.js"
    exit 1
else
    MOUNT_SOURCE=$(echo "${MOUNT_INFO}" | cut -d'|' -f1)
    MOUNT_DEST=$(echo "${MOUNT_INFO}" | cut -d'|' -f2)
    echo -e "${GREEN}✅ Bind mount configurado:${NC}"
    echo "   ${MOUNT_SOURCE} -> ${MOUNT_DEST}"
fi

echo ""

# =====================================================
# 3. VERIFICAR ARCHIVO EN CONTENEDOR
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO ARCHIVO EN CONTENEDOR"
echo "=========================================="
echo ""

if docker exec "${CONTAINER_ID}" test -f /app/supabase-client.js 2>/dev/null; then
    echo -e "${GREEN}✅ Archivo existe en el contenedor${NC}"
    
    # Verificar corrección
    if docker exec "${CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js 2>/dev/null; then
        echo -e "${GREEN}✅ Corrección presente en el contenedor${NC}"
        echo ""
        echo "=========================================="
        echo "✅ TODO ESTÁ CORRECTO"
        echo "=========================================="
        echo ""
        echo "El bind mount está funcionando correctamente."
        echo "Recarga la página del dashboard (F5) y prueba hacer clic en 'Ver' una cotización."
        exit 0
    else
        echo -e "${YELLOW}⚠️  Corrección NO presente en el contenedor${NC}"
        echo "   Esto puede indicar que el contenedor necesita reiniciarse"
    fi
else
    echo -e "${RED}❌ ERROR: El archivo NO existe en el contenedor${NC}"
    echo "   Verifica que el bind mount esté configurado correctamente"
    exit 1
fi

echo ""

# =====================================================
# 4. REINICIAR SERVICIO
# =====================================================
echo "=========================================="
echo "4. REINICIANDO SERVICIO"
echo "=========================================="
echo ""

echo -e "${BLUE}🔄 Reiniciando servicio para aplicar el bind mount...${NC}"
docker service update --force "${SERVICE_NAME}"

echo ""
echo -e "${YELLOW}⏳ Esperando 40 segundos para que el servicio se reinicie completamente...${NC}"
sleep 40

# Verificar nuevo contenedor
NEW_CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${NEW_CONTAINER_ID}" ]; then
    echo -e "${RED}❌ ERROR: No se encontró contenedor después del reinicio${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Nuevo contenedor: ${NEW_CONTAINER_ID}${NC}"
echo ""

# Verificar mount en nuevo contenedor
MOUNT_INFO=$(docker inspect "${NEW_CONTAINER_ID}" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}|{{.Destination}}{{"\n"}}{{end}}{{end}}' | grep "supabase-client.js" || true)

if [ -z "${MOUNT_INFO}" ]; then
    echo -e "${RED}❌ ERROR: El bind mount NO está presente en el nuevo contenedor${NC}"
    echo -e "${YELLOW}⚠️  Verifica la configuración en EasyPanel${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Bind mount presente en nuevo contenedor${NC}"

# Verificar corrección en nuevo contenedor
if docker exec "${NEW_CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js 2>/dev/null; then
    echo -e "${GREEN}✅ Corrección presente en el nuevo contenedor${NC}"
    echo ""
    echo "=========================================="
    echo "✅ CONFIGURACIÓN COMPLETADA"
    echo "=========================================="
    echo ""
    echo "El bind mount está funcionando correctamente."
    echo "Recarga la página del dashboard (F5) y prueba hacer clic en 'Ver' una cotización."
else
    echo -e "${RED}❌ ERROR: La corrección NO está presente en el nuevo contenedor${NC}"
    echo ""
    echo "Verificando tamaño de archivos..."
    SERVER_SIZE=$(stat -c%s "${SUPABASE_FILE}" 2>/dev/null || stat -f%z "${SUPABASE_FILE}" 2>/dev/null)
    CONTAINER_SIZE=$(docker exec "${NEW_CONTAINER_ID}" stat -c%s /app/supabase-client.js 2>/dev/null || echo "0")
    
    echo "   Tamaño en servidor: ${SERVER_SIZE} bytes"
    echo "   Tamaño en contenedor: ${CONTAINER_SIZE} bytes"
    
    if [ "${SERVER_SIZE}" != "${CONTAINER_SIZE}" ]; then
        echo -e "${YELLOW}⚠️  Los tamaños no coinciden, el mount puede no estar funcionando correctamente${NC}"
    fi
    
    exit 1
fi

echo ""
