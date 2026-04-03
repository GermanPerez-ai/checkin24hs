#!/bin/bash
# =====================================================
# ACTUALIZAR supabase-client.js EN EL SERVIDOR
# =====================================================
# Este script actualiza el archivo en el servidor
# para que el bind mount lo propague al contenedor
# =====================================================

set -e

echo "=========================================="
echo "🔄 ACTUALIZANDO supabase-client.js EN SERVIDOR"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SUPABASE_FILE="/root/checkin24hs/supabase-client.js"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main"
BACKUP_FILE="${SUPABASE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# =====================================================
# 1. CREAR BACKUP
# =====================================================
echo "=========================================="
echo "1. CREANDO BACKUP"
echo "=========================================="
echo ""

if [ -f "${SUPABASE_FILE}" ]; then
    cp "${SUPABASE_FILE}" "${BACKUP_FILE}"
    echo -e "${GREEN}✅ Backup creado: ${BACKUP_FILE}${NC}"
else
    echo -e "${YELLOW}⚠️  Archivo no existe, se creará uno nuevo${NC}"
fi

echo ""

# =====================================================
# 2. DESCARGAR DESDE GITHUB
# =====================================================
echo "=========================================="
echo "2. DESCARGANDO DESDE GITHUB"
echo "=========================================="
echo ""

echo -e "${BLUE}📥 Descargando supabase-client.js desde GitHub...${NC}"
if curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${SUPABASE_FILE}"; then
    echo -e "${GREEN}✅ Archivo descargado${NC}"
    
    # Configurar permisos
    chmod 644 "${SUPABASE_FILE}"
    echo -e "${GREEN}✅ Permisos configurados (644)${NC}"
else
    echo -e "${RED}❌ Error al descargar el archivo${NC}"
    exit 1
fi

echo ""

# =====================================================
# 3. VERIFICAR CORRECCIÓN
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO CORRECCIÓN"
echo "=========================================="
echo ""

if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}"; then
    echo -e "${GREEN}✅ Corrección presente en el archivo${NC}"
else
    echo -e "${RED}❌ ERROR: La corrección NO está presente${NC}"
    echo "   Restaurando backup..."
    if [ -f "${BACKUP_FILE}" ]; then
        cp "${BACKUP_FILE}" "${SUPABASE_FILE}"
    fi
    exit 1
fi

# Verificar también el manejo de QuotaExceededError
if grep -q "QuotaExceededError" "${SUPABASE_FILE}"; then
    echo -e "${GREEN}✅ Manejo de QuotaExceededError presente${NC}"
else
    echo -e "${YELLOW}⚠️  Manejo de QuotaExceededError NO encontrado${NC}"
fi

echo ""

# =====================================================
# 4. VERIFICAR TAMAÑO Y LÍNEAS
# =====================================================
echo "=========================================="
echo "4. INFORMACIÓN DEL ARCHIVO"
echo "=========================================="
echo ""

FILE_SIZE=$(stat -c%s "${SUPABASE_FILE}" 2>/dev/null || stat -f%z "${SUPABASE_FILE}" 2>/dev/null)
FILE_LINES=$(wc -l < "${SUPABASE_FILE}" 2>/dev/null || echo "0")

echo "   Tamaño: $(numfmt --to=iec-i --suffix=B ${FILE_SIZE} 2>/dev/null || echo "${FILE_SIZE} bytes")"
echo "   Líneas: ${FILE_LINES}"

# Buscar la línea con la corrección
CORRECTION_LINE=$(grep -n "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}" | cut -d: -f1 | head -1)
if [ ! -z "${CORRECTION_LINE}" ]; then
    echo "   Corrección en línea: ${CORRECTION_LINE}"
fi

echo ""

# =====================================================
# 5. VERIFICAR EN CONTENEDOR (si está corriendo)
# =====================================================
echo "=========================================="
echo "5. VERIFICANDO EN CONTENEDOR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ ! -z "${CONTAINER_ID}" ]; then
    echo -e "${GREEN}✅ Contenedor encontrado: ${CONTAINER_ID}${NC}"
    
    # Verificar mount
    MOUNT_INFO=$(docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}|{{.Destination}}{{"\n"}}{{end}}{{end}}' | grep "supabase-client.js" || true)
    
    if [ ! -z "${MOUNT_INFO}" ]; then
        echo -e "${GREEN}✅ Bind mount configurado${NC}"
        
        # Esperar un momento para que el sistema de archivos se actualice
        sleep 2
        
        # Verificar corrección en contenedor
        if docker exec "${CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js 2>/dev/null; then
            echo -e "${GREEN}✅ Corrección presente en el contenedor${NC}"
        else
            echo -e "${YELLOW}⚠️  Corrección NO presente en el contenedor aún${NC}"
            echo "   Esto puede ser normal - el bind mount puede tardar unos segundos en sincronizar"
            echo "   O el contenedor puede necesitar reiniciarse"
        fi
        
        # Comparar tamaños
        SERVER_SIZE=$(stat -c%s "${SUPABASE_FILE}" 2>/dev/null || stat -f%z "${SUPABASE_FILE}" 2>/dev/null)
        CONTAINER_SIZE=$(docker exec "${CONTAINER_ID}" stat -c%s /app/supabase-client.js 2>/dev/null || echo "0")
        
        echo ""
        echo "   Tamaño en servidor: ${SERVER_SIZE} bytes"
        echo "   Tamaño en contenedor: ${CONTAINER_SIZE} bytes"
        
        if [ "${SERVER_SIZE}" = "${CONTAINER_SIZE}" ]; then
            echo -e "${GREEN}✅ Los tamaños coinciden${NC}"
        else
            echo -e "${YELLOW}⚠️  Los tamaños NO coinciden - el mount puede no estar sincronizado${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Bind mount NO configurado en el contenedor${NC}"
        echo "   El contenedor puede necesitar reiniciarse para aplicar el mount"
    fi
else
    echo -e "${YELLOW}⚠️  No se encontró contenedor en ejecución${NC}"
fi

echo ""

# =====================================================
# RESUMEN FINAL
# =====================================================
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Archivo actualizado en: ${SUPABASE_FILE}"
echo "   - Corrección verificada: ✅"
echo ""
echo "🔄 Si el contenedor no muestra la corrección:"
echo "   1. Espera unos segundos (el bind mount puede tardar en sincronizar)"
echo "   2. O reinicia el servicio: docker service update --force checkin24hs_dashboard"
echo ""
echo "📝 Para verificar manualmente:"
echo "   CONTAINER=\$(docker ps --filter \"name=checkin24hs_dashboard\" --format \"{{.ID}}\" | head -1)"
echo "   docker exec \"\$CONTAINER\" grep -q \"SIEMPRE devolver las cotizaciones obtenidas de Supabase\" /app/supabase-client.js && echo \"✅ OK\" || echo \"❌ NO OK\""
echo ""
