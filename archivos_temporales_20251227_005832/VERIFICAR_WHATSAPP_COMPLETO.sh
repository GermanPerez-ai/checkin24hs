#!/bin/bash

# Script para verificar el estado completo de los 4 servicios de WhatsApp

echo "=========================================="
echo "🔍 Verificación Completa de WhatsApp"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar servicio
verificar_servicio() {
    local SERVICIO=$1
    local PUERTO=$2
    local DOMINIO=$3
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 Verificando: $SERVICIO"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 1. Verificar si el servicio existe y está corriendo
    echo -n "1. Estado del servicio: "
    if docker service ls | grep -q "$SERVICIO"; then
        ESTADO=$(docker service ps $SERVICIO --no-trunc --format '{{.CurrentState}}' | head -1)
        if echo "$ESTADO" | grep -q "Running"; then
            echo -e "${GREEN}✅ Running${NC}"
        else
            echo -e "${RED}❌ $ESTADO${NC}"
        fi
    else
        echo -e "${RED}❌ Servicio no encontrado${NC}"
    fi
    
    # 2. Verificar puerto
    echo -n "2. Puerto $PUERTO: "
    if netstat -tuln 2>/dev/null | grep -q ":$PUERTO " || ss -tuln 2>/dev/null | grep -q ":$PUERTO "; then
        echo -e "${GREEN}✅ En uso${NC}"
    else
        echo -e "${YELLOW}⚠️  No en uso (puede ser normal si está detrás de Traefik)${NC}"
    fi
    
    # 3. Verificar contenedor
    echo -n "3. Contenedor: "
    CONTAINER_ID=$(docker ps --filter "name=$SERVICIO" --format "{{.ID}}" | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        echo -e "${GREEN}✅ Encontrado ($CONTAINER_ID)${NC}"
        
        # Verificar proceso Node.js
        echo -n "4. Proceso Node.js: "
        if docker exec $CONTAINER_ID ps aux 2>/dev/null | grep -q "node.*whatsapp"; then
            echo -e "${GREEN}✅ Corriendo${NC}"
        else
            echo -e "${RED}❌ No encontrado${NC}"
        fi
        
        # Verificar variables de entorno
        echo -n "5. INSTANCE_NUMBER: "
        INSTANCE=$(docker exec $CONTAINER_ID printenv INSTANCE_NUMBER 2>/dev/null)
        if [ -n "$INSTANCE" ]; then
            echo -e "${GREEN}✅ = $INSTANCE${NC}"
        else
            echo -e "${RED}❌ No configurado${NC}"
        fi
        
        echo -n "6. PORT: "
        PORT_ENV=$(docker exec $CONTAINER_ID printenv PORT 2>/dev/null)
        if [ -n "$PORT_ENV" ]; then
            echo -e "${GREEN}✅ = $PORT_ENV${NC}"
        else
            echo -e "${RED}❌ No configurado${NC}"
        fi
        
        echo -n "7. SUPABASE_URL: "
        SUPABASE=$(docker exec $CONTAINER_ID printenv SUPABASE_URL 2>/dev/null)
        if [ -n "$SUPABASE" ]; then
            echo -e "${GREEN}✅ Configurado${NC}"
        else
            echo -e "${RED}❌ No configurado${NC}"
        fi
    else
        echo -e "${RED}❌ No encontrado${NC}"
    fi
    
    # 4. Verificar etiquetas Traefik
    echo -n "8. Etiquetas Traefik: "
    TRAEFIK_ENABLE=$(docker service inspect $SERVICIO --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.enable"}}' 2>/dev/null)
    if [ "$TRAEFIK_ENABLE" = "true" ]; then
        echo -e "${GREEN}✅ Habilitado${NC}"
        
        # Verificar regla de dominio
        TRAEFIK_RULE=$(docker service inspect $SERVICIO --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.routers.'$SERVICIO'.rule"}}' 2>/dev/null)
        echo "   Regla: $TRAEFIK_RULE"
    else
        echo -e "${YELLOW}⚠️  No configurado${NC}"
    fi
    
    # 5. Verificar DNS
    echo -n "9. DNS ($DOMINIO): "
    DNS_IP=$(nslookup $DOMINIO 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | tail -1 | awk '{print $2}')
    if [ -n "$DNS_IP" ]; then
        if [ "$DNS_IP" = "72.61.58.240" ]; then
            echo -e "${GREEN}✅ Apunta a $DNS_IP${NC}"
        else
            echo -e "${YELLOW}⚠️  Apunta a $DNS_IP (esperado: 72.61.58.240)${NC}"
        fi
    else
        echo -e "${RED}❌ No resuelve${NC}"
    fi
    
    # 6. Verificar acceso HTTP
    echo -n "10. Acceso HTTP: "
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$DOMINIO/ 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo -e "${GREEN}✅ Código $HTTP_CODE${NC}"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo -e "${RED}❌ Sin conexión${NC}"
    else
        echo -e "${YELLOW}⚠️  Código $HTTP_CODE${NC}"
    fi
    
    # 7. Verificar acceso HTTPS
    echo -n "11. Acceso HTTPS: "
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://$DOMINIO/ 2>/dev/null || echo "000")
    if [ "$HTTPS_CODE" = "200" ] || [ "$HTTPS_CODE" = "301" ] || [ "$HTTPS_CODE" = "302" ]; then
        echo -e "${GREEN}✅ Código $HTTPS_CODE${NC}"
    elif [ "$HTTPS_CODE" = "000" ]; then
        echo -e "${RED}❌ Sin conexión${NC}"
    else
        echo -e "${YELLOW}⚠️  Código $HTTPS_CODE${NC}"
    fi
    
    # 8. Verificar logs recientes
    echo "12. Últimos logs (últimas 3 líneas):"
    docker service logs $SERVICIO --tail 3 2>/dev/null | tail -3 | sed 's/^/   /'
    
    echo ""
}

# Verificar cada servicio
verificar_servicio "whatsapp1" "3001" "whatsapp1.checkin24hs.com"
verificar_servicio "whatsapp2" "3002" "whatsapp2.checkin24hs.com"
verificar_servicio "whatsapp3" "3003" "whatsapp3.checkin24hs.com"
verificar_servicio "whatsapp4" "3004" "whatsapp4.checkin24hs.com"

# Resumen
echo "=========================================="
echo "📊 Resumen"
echo "=========================================="
echo ""
echo "Servicios Docker:"
docker service ls | grep whatsapp || echo "   Ningún servicio de WhatsApp encontrado"
echo ""
echo "Contenedores corriendo:"
docker ps --filter "name=whatsapp" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "   Ningún contenedor de WhatsApp encontrado"
echo ""
echo "Puertos en uso:"
netstat -tuln 2>/dev/null | grep -E ":(3001|3002|3003|3004) " || ss -tuln 2>/dev/null | grep -E ":(3001|3002|3003|3004) " || echo "   Ningún puerto de WhatsApp en uso"
echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
