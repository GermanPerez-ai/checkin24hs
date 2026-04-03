#!/bin/bash
# Verificar que el servicio CRM fue eliminado correctamente

echo "🔍 VERIFICAR ELIMINACIÓN CRM"
echo "============================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SERVICE_NAME="checkin24hs_crm"

# 1. Verificar servicio
echo "1️⃣ Verificando servicio Docker..."
if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo -e "   ${RED}❌ Servicio aún existe${NC}"
else
    echo -e "   ${GREEN}✅ Servicio eliminado correctamente${NC}"
fi

echo ""

# 2. Verificar contenedores activos
echo "2️⃣ Verificando contenedores activos..."
ACTIVE_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
if [ -n "$ACTIVE_CONTAINERS" ]; then
    echo -e "   ${YELLOW}⚠️  Contenedores activos encontrados:${NC}"
    echo "$ACTIVE_CONTAINERS" | sed 's/^/      /'
    echo ""
    echo "   Esperando 5 segundos para que se detengan automáticamente..."
    sleep 5
    
    # Verificar nuevamente
    ACTIVE_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
    if [ -n "$ACTIVE_CONTAINERS" ]; then
        echo -e "   ${YELLOW}⚠️  Aún hay contenedores activos. Deteniéndolos...${NC}"
        echo "$ACTIVE_CONTAINERS" | xargs -r docker stop
        sleep 2
    else
        echo -e "   ${GREEN}✅ Contenedores se detuvieron automáticamente${NC}"
    fi
else
    echo -e "   ${GREEN}✅ No hay contenedores activos${NC}"
fi

echo ""

# 3. Verificar contenedores detenidos
echo "3️⃣ Verificando contenedores detenidos..."
STOPPED_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
if [ -n "$STOPPED_CONTAINERS" ]; then
    echo -e "   ${CYAN}ℹ️  Contenedores detenidos encontrados:${NC}"
    echo "$STOPPED_CONTAINERS" | sed 's/^/      /'
    echo ""
    read -p "   ¿Eliminar contenedores detenidos? (s/N): " remove
    
    if [[ "$remove" =~ ^[Ss]$ ]]; then
        echo "$STOPPED_CONTAINERS" | xargs -r docker rm -f
        echo -e "   ${GREEN}✅ Contenedores eliminados${NC}"
    else
        echo -e "   ${CYAN}ℹ️  Contenedores conservados${NC}"
    fi
else
    echo -e "   ${GREEN}✅ No hay contenedores detenidos${NC}"
fi

echo ""
echo "============================="
echo "📋 RESUMEN FINAL"
echo "============================="
echo ""

# Verificación final
SERVICE_EXISTS=$(docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$" && echo "Sí" || echo "No")
ACTIVE=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm" | wc -l)
STOPPED=$(docker ps -a --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm" | wc -l)

echo "Servicio Docker: $SERVICE_EXISTS"
echo "Contenedores activos: $ACTIVE"
echo "Contenedores detenidos: $STOPPED"

echo ""
echo "============================="
