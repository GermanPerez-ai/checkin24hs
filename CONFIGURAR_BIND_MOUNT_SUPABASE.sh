#!/bin/bash
# =====================================================
# CONFIGURAR BIND MOUNT PARA supabase-client.js
# =====================================================
# Este script prepara el archivo en el servidor
# y proporciona instrucciones para configurarlo en EasyPanel
# =====================================================

set -e

echo "=========================================="
echo "🔧 CONFIGURAR BIND MOUNT PARA supabase-client.js"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
BIND_MOUNT_DIR="/root/checkin24hs"
SUPABASE_FILE="${BIND_MOUNT_DIR}/supabase-client.js"
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main"

# =====================================================
# 1. VERIFICAR/CREAR DIRECTORIO
# =====================================================
echo "=========================================="
echo "1. PREPARANDO DIRECTORIO"
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
# 2. DESCARGAR/ACTUALIZAR supabase-client.js
# =====================================================
echo "=========================================="
echo "2. DESCARGANDO supabase-client.js"
echo "=========================================="
echo ""

echo -e "${BLUE}📥 Descargando supabase-client.js desde GitHub...${NC}"
if curl -s -L "${GITHUB_REPO}/supabase-client.js" -o "${SUPABASE_FILE}"; then
    echo -e "${GREEN}✅ Archivo descargado en: ${SUPABASE_FILE}${NC}"
    
    # Verificar que tiene la corrección
    if grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${SUPABASE_FILE}"; then
        echo -e "${GREEN}✅ Corrección verificada${NC}"
    else
        echo -e "${RED}❌ ERROR: La corrección no está presente${NC}"
        exit 1
    fi
    
    # Mostrar información del archivo
    FILE_SIZE=$(stat -c%s "${SUPABASE_FILE}" 2>/dev/null || stat -f%z "${SUPABASE_FILE}" 2>/dev/null)
    echo "   Tamaño: $(numfmt --to=iec-i --suffix=B ${FILE_SIZE} 2>/dev/null || echo "${FILE_SIZE} bytes")"
else
    echo -e "${RED}❌ Error al descargar el archivo${NC}"
    exit 1
fi

echo ""

# =====================================================
# 3. VERIFICAR PERMISOS
# =====================================================
echo "=========================================="
echo "3. VERIFICANDO PERMISOS"
echo "=========================================="
echo ""

chmod 644 "${SUPABASE_FILE}"
echo -e "${GREEN}✅ Permisos configurados (644)${NC}"
echo ""

# =====================================================
# 4. INSTRUCCIONES PARA EASYPANEL
# =====================================================
echo "=========================================="
echo "4. INSTRUCCIONES PARA EASYPANEL"
echo "=========================================="
echo ""
echo -e "${YELLOW}📋 Sigue estos pasos en EasyPanel para configurar el bind mount:${NC}"
echo ""
echo "1. Accede a EasyPanel y ve al servicio 'checkin24hs_dashboard'"
echo ""
echo "2. Busca la sección 'Mounts' o 'Volumes' o 'Puntos de montaje'"
echo ""
echo "3. Haz clic en 'Agregar montaje de archivo' (NO 'montaje de enlace' ni 'volumen')"
echo ""
echo "4. Configura el bind mount con estos valores:"
echo ""
echo -e "   ${BLUE}Source/Host Path (Ruta del host):${NC}"
echo "   ${SUPABASE_FILE}"
echo ""
echo -e "   ${BLUE}Destination/Container Path (Ruta del contenedor):${NC}"
echo "   /app/supabase-client.js"
echo ""
echo -e "   ${BLUE}Read Only (Solo lectura):${NC}"
echo "   ❌ Desactivado (déjalo desactivado)"
echo ""
echo "5. Guarda los cambios"
echo ""
echo "6. EasyPanel actualizará automáticamente el servicio"
echo ""
echo -e "${GREEN}✅ Después de configurar el bind mount, el archivo se actualizará automáticamente${NC}"
echo "   cada vez que lo actualices en ${SUPABASE_FILE}"
echo ""

# =====================================================
# 5. VERIFICAR ARCHIVOS ACTUALES
# =====================================================
echo "=========================================="
echo "5. ARCHIVOS CONFIGURADOS COMO BIND MOUNT"
echo "=========================================="
echo ""

echo "📋 Archivos actualmente en ${BIND_MOUNT_DIR}:"
ls -lh "${BIND_MOUNT_DIR}" 2>/dev/null | grep -E "\.(html|js)$" | awk '{print "   " $9 " (" $5 ")"}'

echo ""
echo "📋 Archivos montados actualmente (según contenedor):"
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "${CONTAINER_ID}" ]; then
    docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}{{end}}' | sed 's/^/   /'
else
    echo "   (No se encontró contenedor en ejecución)"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📝 Resumen:"
echo "   - Archivo preparado: ${SUPABASE_FILE}"
echo "   - Siguiente paso: Configurar bind mount en EasyPanel"
echo ""
