#!/bin/bash
# Script para verificar si crm.checkin24hs.com está activo o se puede eliminar

echo "🔍 VERIFICAR CRM.CHECKIN24HS.COM"
echo "=================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 1. Verificar si existe el servicio Docker
echo "1️⃣ Verificando servicio Docker..."
echo ""

SERVICE_NAME="checkin24hs_crm"

if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo -e "   ${GREEN}✅ Servicio encontrado: $SERVICE_NAME${NC}"
    
    # Verificar estado del servicio
    SERVICE_STATUS=$(docker service ps $SERVICE_NAME --format "{{.CurrentState}}" | head -1)
    echo "   Estado: $SERVICE_STATUS"
    
    # Verificar puerto
    PORT=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$PORT" ]; then
        echo "   Puerto: $PORT"
    else
        echo -e "   ${YELLOW}⚠️  No hay puerto publicado${NC}"
    fi
    
    # Verificar labels de Traefik
    TRAEFIK_RULE=$(docker service inspect $SERVICE_NAME --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.routers.crm.rule"}}' 2>/dev/null)
    if [ -n "$TRAEFIK_RULE" ] && [ "$TRAEFIK_RULE" != "<no value>" ]; then
        echo -e "   ${GREEN}✅ Traefik configurado: $TRAEFIK_RULE${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No hay configuración de Traefik${NC}"
    fi
    
    # Verificar red
    NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if echo "$NETWORKS" | grep -q "easypanel"; then
        echo -e "   ${GREEN}✅ En red easypanel${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No está en red easypanel${NC}"
    fi
    
else
    echo -e "   ${RED}❌ Servicio NO encontrado: $SERVICE_NAME${NC}"
    echo -e "   ${CYAN}ℹ️  El servicio no existe en Docker Swarm${NC}"
fi

echo ""

# 2. Verificar contenedores corriendo
echo "2️⃣ Verificando contenedores activos..."
echo ""

CRM_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "crm|checkin24hs_crm")
if [ -n "$CRM_CONTAINERS" ]; then
    echo -e "   ${GREEN}✅ Contenedores encontrados:${NC}"
    echo "$CRM_CONTAINERS" | sed 's/^/      /'
else
    echo -e "   ${CYAN}ℹ️  No hay contenedores CRM corriendo${NC}"
fi

echo ""

# 3. Verificar configuración de Traefik
echo "3️⃣ Verificando configuración en Traefik..."
echo ""

if docker service ls --format "{{.Name}}" | grep -q "^traefik$"; then
    TRAEFIK_LOGS=$(docker service logs traefik --tail 100 2>&1 | grep -iE "crm\.checkin24hs\.com|checkin24hs_crm" | tail -5)
    if [ -n "$TRAEFIK_LOGS" ]; then
        echo -e "   ${GREEN}✅ Referencias encontradas en logs de Traefik:${NC}"
        echo "$TRAEFIK_LOGS" | sed 's/^/      /'
    else
        echo -e "   ${CYAN}ℹ️  No hay referencias recientes en Traefik${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  Traefik no encontrado como servicio${NC}"
fi

echo ""

# 4. Verificar archivos del CRM
echo "4️⃣ Verificando archivos del CRM..."
echo ""

if [ -d "crm" ]; then
    CRM_FILES=$(find crm -type f -name "*.html" -o -name "*.js" | wc -l)
    echo -e "   ${GREEN}✅ Directorio 'crm' existe${NC}"
    echo "   Archivos encontrados: $CRM_FILES"
    
    # Verificar si hay referencias en otros archivos
    echo ""
    echo "   Buscando referencias a crm.checkin24hs.com en código..."
    REFERENCES=$(grep -r "crm\.checkin24hs\.com" --include="*.sh" --include="*.md" --include="*.js" --include="*.html" . 2>/dev/null | grep -v "archivos_temporales" | grep -v "backups" | wc -l)
    echo "   Referencias encontradas: $REFERENCES"
    
    if [ "$REFERENCES" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Hay referencias en archivos de configuración/documentación${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  Directorio 'crm' no existe${NC}"
fi

echo ""

# 5. Verificar DNS
echo "5️⃣ Verificando resolución DNS..."
echo ""

DNS_RESULT=$(nslookup crm.checkin24hs.com 2>&1 | grep -A 2 "Name:" | grep "Address:" | tail -1 | awk '{print $2}')
if [ -n "$DNS_RESULT" ] && [ "$DNS_RESULT" != "" ]; then
    echo -e "   ${GREEN}✅ DNS configurado: crm.checkin24hs.com → $DNS_RESULT${NC}"
else
    echo -e "   ${YELLOW}⚠️  DNS no resuelve o no está configurado${NC}"
fi

echo ""

# 6. Resumen y recomendación
echo "=================================="
echo "📋 RESUMEN"
echo "=================================="
echo ""

if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo -e "${YELLOW}⚠️  SERVICIO ACTIVO${NC}"
    echo ""
    echo "El servicio $SERVICE_NAME existe y puede estar activo."
    echo ""
    echo "Para eliminar el servicio:"
    echo "  1. docker service rm $SERVICE_NAME"
    echo "  2. Eliminar configuración de Traefik (si existe)"
    echo "  3. Eliminar dominio en EasyPanel (si está configurado)"
    echo "  4. Eliminar DNS (si quieres eliminar completamente)"
else
    echo -e "${GREEN}✅ SERVICIO NO EXISTE${NC}"
    echo ""
    echo "El servicio $SERVICE_NAME no existe en Docker Swarm."
    echo ""
    echo "Puedes:"
    echo "  1. Eliminar archivos del directorio 'crm' (si no los usas)"
    echo "  2. Eliminar referencias en documentación"
    echo "  3. Eliminar DNS de crm.checkin24hs.com"
fi

echo ""
echo "=================================="
