#!/bin/bash
# Script para eliminar el servicio CRM de forma segura

echo "🗑️  ELIMINAR SERVICIO CRM"
echo "=========================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SERVICE_NAME="checkin24hs_crm"

# 1. Verificar que el servicio existe
echo "1️⃣ Verificando servicio..."
echo ""

if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo -e "   ${GREEN}✅ Servicio encontrado: $SERVICE_NAME${NC}"
    
    # Mostrar información del servicio
    echo ""
    echo "   Información del servicio:"
    docker service ps $SERVICE_NAME --no-trunc | head -3
    echo ""
    
    # Confirmar eliminación
    echo -e "   ${YELLOW}⚠️  Estás a punto de eliminar el servicio $SERVICE_NAME${NC}"
    echo ""
    read -p "   ¿Continuar? (s/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        echo -e "   ${CYAN}ℹ️  Operación cancelada${NC}"
        exit 0
    fi
    
    echo ""
    echo "2️⃣ Eliminando servicio..."
    echo ""
    
    # Eliminar el servicio
    if docker service rm $SERVICE_NAME; then
        echo -e "   ${GREEN}✅ Servicio eliminado correctamente${NC}"
    else
        echo -e "   ${RED}❌ Error al eliminar el servicio${NC}"
        exit 1
    fi
    
    # Esperar un momento para que Docker procese la eliminación
    sleep 2
    
    echo ""
    echo "3️⃣ Verificando eliminación..."
    echo ""
    
    # Verificar que el servicio no existe
    if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
        echo -e "   ${RED}❌ El servicio aún existe${NC}"
        exit 1
    else
        echo -e "   ${GREEN}✅ Servicio eliminado correctamente${NC}"
    fi
    
    # Verificar contenedores
    CRM_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
    if [ -n "$CRM_CONTAINERS" ]; then
        echo -e "   ${YELLOW}⚠️  Aún hay contenedores activos:${NC}"
        echo "$CRM_CONTAINERS" | sed 's/^/      /'
        echo ""
        echo "   Esperando 5 segundos para que se detengan..."
        sleep 5
        
        # Verificar nuevamente
        CRM_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
        if [ -n "$CRM_CONTAINERS" ]; then
            echo -e "   ${YELLOW}⚠️  Contenedores aún activos. Puedes detenerlos manualmente si es necesario.${NC}"
        else
            echo -e "   ${GREEN}✅ Todos los contenedores se detuvieron${NC}"
        fi
    else
        echo -e "   ${GREEN}✅ No hay contenedores activos${NC}"
    fi
    
    echo ""
    echo "4️⃣ Verificando contenedores detenidos..."
    echo ""
    
    STOPPED_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
    if [ -n "$STOPPED_CONTAINERS" ]; then
        echo -e "   ${CYAN}ℹ️  Contenedores detenidos encontrados:${NC}"
        echo "$STOPPED_CONTAINERS" | sed 's/^/      /'
        echo ""
        read -p "   ¿Eliminar contenedores detenidos? (s/N): " remove_containers
        
        if [[ "$remove_containers" =~ ^[Ss]$ ]]; then
            echo "$STOPPED_CONTAINERS" | xargs -r docker rm -f
            echo -e "   ${GREEN}✅ Contenedores eliminados${NC}"
        else
            echo -e "   ${CYAN}ℹ️  Contenedores conservados${NC}"
        fi
    else
        echo -e "   ${GREEN}✅ No hay contenedores detenidos${NC}"
    fi
    
else
    echo -e "   ${CYAN}ℹ️  El servicio $SERVICE_NAME no existe${NC}"
    echo ""
    echo "   Verificando contenedores..."
    
    CRM_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
    if [ -n "$CRM_CONTAINERS" ]; then
        echo -e "   ${YELLOW}⚠️  Hay contenedores activos sin servicio:${NC}"
        echo "$CRM_CONTAINERS" | sed 's/^/      /'
    else
        echo -e "   ${GREEN}✅ No hay contenedores activos${NC}"
    fi
fi

echo ""
echo "=========================="
echo "📋 RESUMEN"
echo "=========================="
echo ""

# Verificación final
echo "Estado final:"
echo ""

# Verificar servicio
if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo -e "   ${RED}❌ Servicio: Aún existe${NC}"
else
    echo -e "   ${GREEN}✅ Servicio: Eliminado${NC}"
fi

# Verificar contenedores activos
ACTIVE_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
if [ -n "$ACTIVE_CONTAINERS" ]; then
    echo -e "   ${YELLOW}⚠️  Contenedores activos: Sí${NC}"
else
    echo -e "   ${GREEN}✅ Contenedores activos: No${NC}"
fi

echo ""
echo "=========================="
echo ""
echo -e "${CYAN}📝 Próximos pasos:${NC}"
echo ""
echo "1. Eliminar dominio en EasyPanel (si está configurado):"
echo "   - Ve a EasyPanel → Servicios → checkin24hs_crm"
echo "   - Elimina el dominio crm.checkin24hs.com"
echo ""
echo "2. Eliminar DNS (opcional):"
echo "   - Ve a tu proveedor de DNS"
echo "   - Elimina el registro A de crm.checkin24hs.com"
echo ""
echo "3. Archivar directorio crm/ (opcional):"
echo "   - Los archivos en crm/ no se usan por dashboard.html"
echo "   - Puedes moverlos a backups si quieres conservarlos"
echo ""
echo "=========================="
