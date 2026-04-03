#!/bin/bash
# =====================================================
# APLICAR BIND MOUNT DIRECTAMENTE AL SERVICIO
# =====================================================
# Este script aplica el bind mount directamente usando
# docker service update, como alternativa si EasyPanel no funciona
# =====================================================

set -e

echo "=========================================="
echo "🔧 APLICANDO BIND MOUNT DIRECTAMENTE"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVICE_NAME="checkin24hs_dashboard"
SUPABASE_SOURCE="/root/checkin24hs/supabase-client.js"
SUPABASE_DEST="/app/supabase-client.js"

# Verificar que el archivo existe
if [ ! -f "${SUPABASE_SOURCE}" ]; then
    echo -e "${RED}❌ ERROR: El archivo ${SUPABASE_SOURCE} no existe${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archivo verificado: ${SUPABASE_SOURCE}${NC}"
echo ""

# Obtener mounts actuales del servicio
echo "=========================================="
echo "1. OBTENIENDO MOUNTS ACTUALES"
echo "=========================================="
echo ""

CURRENT_MOUNTS=$(docker service inspect "${SERVICE_NAME}" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}}|{{.Source}}|{{.Destination}}{{" "}}{{end}}' 2>/dev/null || echo "")

if [ ! -z "${CURRENT_MOUNTS}" ]; then
    echo "📋 Mounts actuales:"
    echo "${CURRENT_MOUNTS}" | tr ' ' '\n' | while IFS='|' read -r TYPE SOURCE DEST; do
        if [ ! -z "${TYPE}" ]; then
            echo "   ${TYPE}: ${SOURCE} -> ${DEST}"
        fi
    done
else
    echo "⚠️  No se encontraron mounts configurados"
fi

echo ""

# Verificar si ya está configurado
if echo "${CURRENT_MOUNTS}" | grep -q "supabase-client.js"; then
    echo -e "${YELLOW}⚠️  El mount de supabase-client.js ya está en la configuración${NC}"
    echo "   Pero no se está aplicando al contenedor"
    echo ""
    echo "   Esto puede indicar que EasyPanel tiene una configuración diferente"
    echo "   o que el servicio necesita ser recreado"
    echo ""
    echo "   SOLUCIÓN RECOMENDADA:"
    echo "   1. Ve a EasyPanel y elimina el mount de supabase-client.js"
    echo "   2. Guarda los cambios"
    echo "   3. Vuelve a agregar el mount de supabase-client.js"
    echo "   4. Guarda y despliega los cambios"
    exit 0
fi

echo "=========================================="
echo "2. APLICANDO MOUNT AL SERVICIO"
echo "=========================================="
echo ""

echo -e "${BLUE}🔄 Aplicando bind mount al servicio...${NC}"
echo ""

# Construir comando de actualización
# Necesitamos agregar el mount a los existentes
MOUNT_OPTION="--mount type=bind,source=${SUPABASE_SOURCE},target=${SUPABASE_DEST}"

# Intentar actualizar el servicio
if docker service update ${MOUNT_OPTION} "${SERVICE_NAME}" 2>/dev/null; then
    echo -e "${GREEN}✅ Mount aplicado al servicio${NC}"
else
    echo -e "${RED}❌ ERROR: No se pudo aplicar el mount directamente${NC}"
    echo ""
    echo "   Docker Swarm requiere que todos los mounts se especifiquen juntos"
    echo "   y EasyPanel puede estar gestionando esto de manera diferente"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Ve a EasyPanel → Servicio checkin24hs_dashboard"
    echo "   2. Elimina el mount de supabase-client.js si existe"
    echo "   3. Guarda los cambios"
    echo "   4. Vuelve a agregar el mount de supabase-client.js"
    echo "   5. Busca un botón 'Deploy', 'Update' o 'Apply' y haz clic"
    echo "   6. O simplemente guarda nuevamente"
    exit 1
fi

echo ""
echo -e "${YELLOW}⏳ Esperando 40 segundos para que el servicio se actualice...${NC}"
sleep 40

echo ""

# Verificar
echo "=========================================="
echo "3. VERIFICANDO RESULTADO"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo -e "${RED}❌ No se encontró contenedor después de la actualización${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Contenedor: ${CONTAINER_ID}${NC}"
echo ""

# Verificar mount
MOUNT_CHECK=$(docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}|{{.Destination}}{{"\n"}}{{end}}{{end}}' | grep "supabase-client.js" || true)

if [ ! -z "${MOUNT_CHECK}" ]; then
    echo -e "${GREEN}✅ Bind mount presente en el contenedor${NC}"
    echo "   ${MOUNT_CHECK}"
    echo ""
    
    # Verificar corrección
    if docker exec "${CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js 2>/dev/null; then
        echo -e "${GREEN}✅ Corrección presente en el contenedor${NC}"
        echo ""
        echo "=========================================="
        echo "✅ CONFIGURACIÓN COMPLETADA"
        echo "=========================================="
        echo ""
        echo "El bind mount está funcionando correctamente."
        echo "Recarga la página del dashboard (F5) y prueba hacer clic en 'Ver' una cotización."
    else
        echo -e "${YELLOW}⚠️  Corrección NO presente aún${NC}"
        echo "   Espera unos segundos más o reinicia el servicio"
    fi
else
    echo -e "${RED}❌ Bind mount NO presente en el contenedor${NC}"
    echo ""
    echo "   El mount no se aplicó correctamente"
    echo "   Es probable que EasyPanel esté gestionando los mounts de manera diferente"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Ve a EasyPanel y aplica los cambios manualmente"
    echo "   2. O contacta al soporte de EasyPanel"
fi

echo ""
