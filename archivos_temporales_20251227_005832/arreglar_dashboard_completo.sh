#!/bin/bash

# Script para arreglar el dashboard completamente
# Ejecuta todas las verificaciones y correcciones necesarias

echo "=========================================="
echo "🔧 Arreglando Dashboard - Verificación Completa"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar estado de PM2
echo "📊 1. Verificando estado de PM2..."
pm2 list | grep dashboard
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dashboard encontrado en PM2${NC}"
    DASHBOARD_STATUS=$(pm2 jlist | grep -A 5 '"name":"dashboard"' | grep '"status"' | cut -d'"' -f4)
    echo "   Estado: $DASHBOARD_STATUS"
    
    if [ "$DASHBOARD_STATUS" != "online" ]; then
        echo -e "${YELLOW}⚠️  Dashboard no está online, reiniciando...${NC}"
        pm2 restart dashboard
        sleep 3
    fi
else
    echo -e "${RED}❌ Dashboard NO encontrado en PM2${NC}"
    echo -e "${YELLOW}⚠️  Creando proceso dashboard...${NC}"
    cd ~/checkin24hs
    pm2 start server.js --name dashboard
    pm2 save
    sleep 3
fi
echo ""

# 2. Verificar puerto 3010
echo "🔌 2. Verificando puerto 3010..."
PORT_CHECK=$(ss -tulpn 2>/dev/null | grep 3010 || netstat -tulpn 2>/dev/null | grep 3010)
if [ -n "$PORT_CHECK" ]; then
    echo -e "${GREEN}✅ Puerto 3010 está escuchando${NC}"
    echo "   $PORT_CHECK"
else
    echo -e "${RED}❌ Puerto 3010 NO está escuchando${NC}"
    echo -e "${YELLOW}⚠️  Reiniciando dashboard...${NC}"
    pm2 restart dashboard
    sleep 5
    PORT_CHECK=$(ss -tulpn 2>/dev/null | grep 3010 || netstat -tulpn 2>/dev/null | grep 3010)
    if [ -n "$PORT_CHECK" ]; then
        echo -e "${GREEN}✅ Puerto 3010 ahora está escuchando${NC}"
    else
        echo -e "${RED}❌ ERROR: Puerto 3010 aún no está escuchando${NC}"
    fi
fi
echo ""

# 3. Probar acceso local
echo "🌐 3. Probando acceso local al dashboard..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3010 2>/dev/null)
if [ "$HTTP_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Dashboard responde correctamente (HTTP $HTTP_RESPONSE)${NC}"
else
    echo -e "${RED}❌ Dashboard NO responde correctamente (HTTP $HTTP_RESPONSE)${NC}"
    echo -e "${YELLOW}⚠️  Revisando logs...${NC}"
    pm2 logs dashboard --lines 10 --nostream
fi
echo ""

# 4. Verificar configuración de Traefik
echo "🔧 4. Verificando configuración de Traefik..."
TRAEFIK_URL=$(grep -A 5 '"checkin24hs_dashboard-1"' /etc/easypanel/traefik/config/main.yaml 2>/dev/null | grep '"url"' | head -1)
if echo "$TRAEFIK_URL" | grep -q "72.61.58.240:3010"; then
    echo -e "${GREEN}✅ Traefik configurado correctamente${NC}"
    echo "   $TRAEFIK_URL"
else
    echo -e "${YELLOW}⚠️  Traefik NO está configurado correctamente${NC}"
    echo "   Configuración actual: $TRAEFIK_URL"
    echo -e "${YELLOW}⚠️  Corrigiendo configuración...${NC}"
    
    # Hacer backup
    cp /etc/easypanel/traefik/config/main.yaml /etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)
    
    # Corregir URL
    sed -i 's|"url": "http://checkin24hs_dashboard:80/"|"url": "http://72.61.58.240:3010"|g' /etc/easypanel/traefik/config/main.yaml
    sed -i 's|"url": "http://easypanel:3000"|"url": "http://72.61.58.240:3010"|g' /etc/easypanel/traefik/config/main.yaml
    
    # Verificar que se corrigió
    TRAEFIK_URL_NEW=$(grep -A 5 '"checkin24hs_dashboard-1"' /etc/easypanel/traefik/config/main.yaml | grep '"url"' | head -1)
    if echo "$TRAEFIK_URL_NEW" | grep -q "72.61.58.240:3010"; then
        echo -e "${GREEN}✅ Configuración corregida${NC}"
        echo "   Nueva configuración: $TRAEFIK_URL_NEW"
        
        # Reiniciar Traefik
        echo -e "${YELLOW}⚠️  Reiniciando Traefik...${NC}"
        docker service update --force traefik 2>/dev/null || docker restart traefik 2>/dev/null || echo "⚠️  No se pudo reiniciar Traefik automáticamente"
        echo "   Espera 10-15 segundos para que Traefik se reinicie"
    else
        echo -e "${RED}❌ ERROR: No se pudo corregir la configuración${NC}"
    fi
fi
echo ""

# 5. Verificar logs recientes
echo "📋 5. Últimos logs del dashboard:"
pm2 logs dashboard --lines 5 --nostream 2>/dev/null | tail -5
echo ""

# 6. Resumen final
echo "=========================================="
echo "📊 RESUMEN FINAL"
echo "=========================================="

# Verificar estado final
DASHBOARD_FINAL=$(pm2 jlist | grep -A 5 '"name":"dashboard"' | grep '"status"' | cut -d'"' -f4)
PORT_FINAL=$(ss -tulpn 2>/dev/null | grep 3010 || netstat -tulpn 2>/dev/null | grep 3010)
HTTP_FINAL=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3010 2>/dev/null)

if [ "$DASHBOARD_FINAL" = "online" ] && [ -n "$PORT_FINAL" ] && [ "$HTTP_FINAL" = "200" ]; then
    echo -e "${GREEN}✅ TODO ESTÁ FUNCIONANDO CORRECTAMENTE${NC}"
    echo ""
    echo "✅ Dashboard: $DASHBOARD_FINAL"
    echo "✅ Puerto 3010: Escuchando"
    echo "✅ HTTP Response: $HTTP_FINAL"
    echo ""
    echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com"
    echo "   (Espera 10-15 segundos si se reinició Traefik)"
else
    echo -e "${RED}❌ HAY PROBLEMAS QUE NECESITAN ATENCIÓN${NC}"
    echo ""
    [ "$DASHBOARD_FINAL" != "online" ] && echo -e "${RED}❌ Dashboard: $DASHBOARD_FINAL${NC}" || echo -e "${GREEN}✅ Dashboard: $DASHBOARD_FINAL${NC}"
    [ -z "$PORT_FINAL" ] && echo -e "${RED}❌ Puerto 3010: NO escuchando${NC}" || echo -e "${GREEN}✅ Puerto 3010: Escuchando${NC}"
    [ "$HTTP_FINAL" != "200" ] && echo -e "${RED}❌ HTTP Response: $HTTP_FINAL${NC}" || echo -e "${GREEN}✅ HTTP Response: $HTTP_FINAL${NC}"
    echo ""
    echo "🔍 Revisa los logs con: pm2 logs dashboard"
fi

echo ""
echo "=========================================="

