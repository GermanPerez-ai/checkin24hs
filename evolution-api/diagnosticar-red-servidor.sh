#!/bin/bash

echo "🔍 DIAGNÓSTICO DE RED Y PROXY DEL SERVIDOR"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar conectividad básica
echo "1️⃣  Verificando conectividad básica..."
echo ""

echo "   📡 Ping a web.whatsapp.com:"
if ping -c 3 -W 5 web.whatsapp.com > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Conectividad OK${NC}"
else
    echo -e "   ${RED}❌ Sin conectividad${NC}"
fi
echo ""

echo "   📡 Ping a c.whatsapp.com:"
if ping -c 3 -W 5 c.whatsapp.com > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Conectividad OK${NC}"
else
    echo -e "   ${RED}❌ Sin conectividad${NC}"
fi
echo ""

# 2. Verificar HTTP/HTTPS a WhatsApp
echo "2️⃣  Verificando acceso HTTP/HTTPS a WhatsApp..."
echo ""

echo "   🌐 curl a https://web.whatsapp.com:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://web.whatsapp.com 2>&1)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "   ${GREEN}✅ Acceso OK (HTTP $HTTP_CODE)${NC}"
elif [ "$HTTP_CODE" == "000" ]; then
    echo -e "   ${RED}❌ Sin respuesta (timeout o bloqueo)${NC}"
else
    echo -e "   ${YELLOW}⚠️  Respuesta: HTTP $HTTP_CODE${NC}"
fi
echo ""

echo "   🌐 curl detallado (verificar certificados):"
curl -v --max-time 10 https://web.whatsapp.com 2>&1 | grep -E "(Connected|SSL|TLS|HTTP|error|timeout)" | head -10
echo ""

# 3. Verificar desde dentro del contenedor Docker
echo "3️⃣  Verificando conectividad desde el contenedor Evolution API..."
echo ""

if docker ps | grep -q evolution-api-checkin24hs; then
    echo "   🐳 Contenedor está corriendo"
    echo ""
    
    echo "   📡 Ping desde contenedor:"
    docker exec evolution-api-checkin24hs ping -c 2 -W 3 web.whatsapp.com 2>&1 | tail -3
    echo ""
    
    echo "   🌐 curl desde contenedor:"
    HTTP_CODE_CONTAINER=$(docker exec evolution-api-checkin24hs curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://web.whatsapp.com 2>&1)
    if [ "$HTTP_CODE_CONTAINER" == "200" ]; then
        echo -e "   ${GREEN}✅ Acceso OK desde contenedor (HTTP $HTTP_CODE_CONTAINER)${NC}"
    elif [ "$HTTP_CODE_CONTAINER" == "000" ]; then
        echo -e "   ${RED}❌ Sin respuesta desde contenedor${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Respuesta desde contenedor: HTTP $HTTP_CODE_CONTAINER${NC}"
    fi
    echo ""
else
    echo -e "   ${YELLOW}⚠️  Contenedor no está corriendo${NC}"
    echo ""
fi

# 4. Verificar variables de proxy del sistema
echo "4️⃣  Verificando variables de proxy del sistema..."
echo ""

if [ -n "$http_proxy" ] || [ -n "$HTTP_PROXY" ]; then
    echo -e "   ${YELLOW}⚠️  http_proxy configurado: ${http_proxy:-$HTTP_PROXY}${NC}"
else
    echo "   ℹ️  No hay http_proxy configurado"
fi

if [ -n "$https_proxy" ] || [ -n "$HTTPS_PROXY" ]; then
    echo -e "   ${YELLOW}⚠️  https_proxy configurado: ${https_proxy:-$HTTPS_PROXY}${NC}"
else
    echo "   ℹ️  No hay https_proxy configurado"
fi

if [ -n "$no_proxy" ] || [ -n "$NO_PROXY" ]; then
    echo -e "   ${YELLOW}⚠️  no_proxy configurado: ${no_proxy:-$NO_PROXY}${NC}"
fi
echo ""

# 5. Verificar configuración de proxy en Docker
echo "5️⃣  Verificando configuración de proxy en Docker..."
echo ""

if [ -f /etc/systemd/system/docker.service.d/http-proxy.conf ]; then
    echo -e "   ${YELLOW}⚠️  Docker tiene proxy configurado:${NC}"
    cat /etc/systemd/system/docker.service.d/http-proxy.conf 2>/dev/null || echo "   (no se puede leer)"
else
    echo "   ℹ️  Docker no tiene proxy configurado"
fi
echo ""

# Verificar variables de proxy en docker-compose
if [ -f /root/checkin24hs/evolution-api/docker-compose.yml ]; then
    if grep -q "environment:" /root/checkin24hs/evolution-api/docker-compose.yml && \
       grep -q "PROXY\|HTTP_PROXY\|HTTPS_PROXY" /root/checkin24hs/evolution-api/docker-compose.yml; then
        echo -e "   ${YELLOW}⚠️  docker-compose.yml tiene variables de proxy:${NC}"
        grep -i "PROXY" /root/checkin24hs/evolution-api/docker-compose.yml | head -5
    else
        echo "   ℹ️  docker-compose.yml no tiene proxy configurado"
    fi
fi
echo ""

# 6. Verificar DNS
echo "6️⃣  Verificando DNS..."
echo ""

echo "   🔍 Resolución DNS de web.whatsapp.com:"
DNS_RESULT=$(nslookup web.whatsapp.com 2>&1 | grep -A 2 "Name:" | tail -1)
if [ -n "$DNS_RESULT" ]; then
    echo "   ✅ $DNS_RESULT"
else
    echo -e "   ${RED}❌ No se pudo resolver${NC}"
fi
echo ""

# Verificar servidores DNS
echo "   🔍 Servidores DNS configurados:"
cat /etc/resolv.conf | grep "nameserver" | head -3
echo ""

# 7. Verificar firewall (iptables)
echo "7️⃣  Verificando reglas de firewall (iptables)..."
echo ""

if command -v iptables > /dev/null 2>&1; then
    OUTPUT_RULES=$(iptables -L OUTPUT -n -v 2>/dev/null | wc -l)
    if [ "$OUTPUT_RULES" -gt 3 ]; then
        echo -e "   ${YELLOW}⚠️  Hay reglas de firewall configuradas (${OUTPUT_RULES} líneas)${NC}"
        echo "   ℹ️  Ejecuta 'iptables -L OUTPUT -n -v' para ver detalles"
    else
        echo "   ℹ️  Sin reglas de firewall restrictivas visibles"
    fi
else
    echo "   ℹ️  iptables no disponible"
fi
echo ""

# 8. Verificar rutas de red
echo "8️⃣  Verificando rutas de red..."
echo ""

echo "   🔍 Ruta predeterminada:"
ip route | grep default | head -1
echo ""

echo "   🔍 IP pública del servidor (salida):"
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>&1)
if [ -n "$PUBLIC_IP" ]; then
    echo "   ✅ IP pública: $PUBLIC_IP"
else
    echo -e "   ${YELLOW}⚠️  No se pudo obtener IP pública${NC}"
fi
echo ""

# 9. Verificar puertos bloqueados
echo "9️⃣  Verificando conexiones salientes a puertos WhatsApp comunes..."
echo ""

echo "   🔌 Puerto 443 (HTTPS):"
if timeout 3 bash -c "echo > /dev/tcp/web.whatsapp.com/443" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Puerto 443 accesible${NC}"
else
    echo -e "   ${RED}❌ Puerto 443 bloqueado o inaccesible${NC}"
fi
echo ""

echo "   🔌 Puerto 80 (HTTP):"
if timeout 3 bash -c "echo > /dev/tcp/web.whatsapp.com/80" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Puerto 80 accesible${NC}"
else
    echo -e "   ${YELLOW}⚠️  Puerto 80 no accesible (normal, WhatsApp usa HTTPS)${NC}"
fi
echo ""

# 10. Verificar logs recientes de Evolution API
echo "🔟 Verificando errores de red en logs de Evolution API..."
echo ""

if docker ps | grep -q evolution-api-checkin24hs; then
    NETWORK_ERRORS=$(docker logs evolution-api-checkin24hs 2>&1 | grep -iE "network|timeout|connection|failed|error|refused|ECONN" | tail -5)
    if [ -n "$NETWORK_ERRORS" ]; then
        echo -e "   ${YELLOW}⚠️  Errores de red encontrados en logs:${NC}"
        echo "$NETWORK_ERRORS" | sed 's/^/   /'
    else
        echo "   ℹ️  No se encontraron errores de red obvios en logs recientes"
    fi
else
    echo "   ℹ️  Contenedor no está corriendo"
fi
echo ""

# RESUMEN
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Si hay problemas detectados:"
echo ""
echo "1. ${YELLOW}Proxy configurado:${NC}"
echo "   - Verifica si es necesario para WhatsApp"
echo "   - Considera agregar *.whatsapp.com a NO_PROXY"
echo ""
echo "2. ${YELLOW}Firewall bloqueando:${NC}"
echo "   - Verifica reglas iptables/UFW"
echo "   - Asegúrate de permitir salida HTTPS (443)"
echo ""
echo "3. ${YELLOW}DNS no resuelve:${NC}"
echo "   - Cambia servidores DNS (8.8.8.8, 1.1.1.1)"
echo ""
echo "4. ${YELLOW}Proveedor bloquea WhatsApp:${NC}"
echo "   - Algunos proveedores bloquean WhatsApp"
echo "   - Considera VPN o proxy para WhatsApp"
echo ""
echo "5. ${YELLOW}Configurar proxy en Docker si es necesario:${NC}"
echo "   - Agregar variables al docker-compose.yml:"
echo "     environment:"
echo "       HTTP_PROXY: ..."
echo "       HTTPS_PROXY: ..."
echo "       NO_PROXY: localhost,127.0.0.1"
echo ""
