#!/bin/bash

echo "🔧 SOLUCIONANDO PROBLEMA DE RED EN CONTENEDOR"
echo "============================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📋 DIAGNÓSTICO:"
echo ""
echo "   ✅ Servidor puede conectarse a WhatsApp (HTTP 200)"
echo "   ❌ Contenedor NO puede conectarse (100% packet loss)"
echo ""
echo "   🔍 El contenedor no tiene acceso a internet."
echo ""

# Verificar configuración actual
echo "1️⃣  Verificando configuración actual de docker-compose.yml..."
echo ""

cd /root/checkin24hs/evolution-api

if [ -f docker-compose.yml ]; then
    echo "   📄 docker-compose.yml encontrado"
    
    # Verificar si tiene configuración de red
    if grep -q "network_mode:\|dns:\|extra_hosts:" docker-compose.yml; then
        echo -e "   ${YELLOW}⚠️  Ya tiene configuración de red${NC}"
        grep -E "network_mode|dns|extra_hosts" docker-compose.yml | head -5
    else
        echo "   ℹ️  Sin configuración de red específica"
    fi
else
    echo -e "   ${RED}❌ docker-compose.yml no encontrado${NC}"
    exit 1
fi
echo ""

# Verificar conectividad del contenedor
echo "2️⃣  Verificando conectividad del contenedor..."
echo ""

if docker ps | grep -q evolution-api-checkin24hs; then
    echo "   🐳 Contenedor está corriendo"
    
    echo "   📡 Probando DNS en el contenedor:"
    if docker exec evolution-api-checkin24hs nslookup web.whatsapp.com 2>&1 | grep -q "Address"; then
        echo -e "   ${GREEN}✅ DNS funciona en el contenedor${NC}"
    else
        echo -e "   ${RED}❌ DNS NO funciona en el contenedor${NC}"
    fi
    echo ""
    
    echo "   🔍 Verificando /etc/resolv.conf en el contenedor:"
    docker exec evolution-api-checkin24hs cat /etc/resolv.conf 2>&1 | head -5
    echo ""
    
    echo "   🔍 Verificando rutas de red en el contenedor:"
    docker exec evolution-api-checkin24hs ip route 2>&1 | head -3
    echo ""
else
    echo -e "   ${YELLOW}⚠️  Contenedor no está corriendo${NC}"
fi
echo ""

# Verificar configuración de red de Docker
echo "3️⃣  Verificando configuración de red de Docker..."
echo ""

echo "   🔍 Redes de Docker:"
docker network ls | grep evolution || echo "   (no hay red evolution específica)"
echo ""

if docker ps | grep -q evolution-api-checkin24hs; then
    CONTAINER_NETWORK=$(docker inspect evolution-api-checkin24hs | grep -A 5 "Networks" | head -3)
    echo "   🔍 Red del contenedor:"
    echo "$CONTAINER_NETWORK"
fi
echo ""

# SOLUCIÓN: Actualizar docker-compose.yml
echo "4️⃣  SOLUCIONANDO: Actualizando docker-compose.yml con configuración de red..."
echo ""

# Crear backup
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
echo "   ✅ Backup creado: docker-compose.yml.backup.*"
echo ""

# Verificar DNS del servidor
echo "   🔍 Obteniendo DNS del servidor:"
SERVER_DNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)
if [ -n "$SERVER_DNS" ]; then
    echo "   ✅ DNS del servidor: $SERVER_DNS"
else
    SERVER_DNS="8.8.8.8"
    echo "   ℹ️  Usando DNS por defecto: $SERVER_DNS"
fi
echo ""

# Actualizar docker-compose.yml
echo "   📝 Actualizando docker-compose.yml..."

# Leer el archivo actual
CURRENT_FILE=$(cat docker-compose.yml)

# Verificar si ya tiene dns configurado
if echo "$CURRENT_FILE" | grep -q "dns:"; then
    echo -e "   ${YELLOW}⚠️  Ya tiene DNS configurado, solo actualizando...${NC}"
    # Actualizar DNS existente
    sed -i "s|- \(8\.8\.8\.8\|1\.1\.1\.1\|nameserver\).*|    - $SERVER_DNS|g" docker-compose.yml
    sed -i "s|dns:|      dns:|g" docker-compose.yml
else
    # Agregar DNS y network_mode después de environment
    # Buscar el patrón después de environment y antes de volumes
    if echo "$CURRENT_FILE" | grep -q "environment:"; then
        # Insertar después de environment
        sed -i "/environment:/a\\
      dns:\\
        - $SERVER_DNS\\
        - 8.8.8.8\\
        - 1.1.1.1\\
      network_mode: bridge" docker-compose.yml
    fi
fi

echo "   ✅ docker-compose.yml actualizado"
echo ""

# Mostrar cambios
echo "   📋 Cambios aplicados:"
echo "   - DNS configurado: $SERVER_DNS, 8.8.8.8, 1.1.1.1"
echo "   - network_mode: bridge"
echo ""

# Reiniciar contenedor
echo "5️⃣  Reiniciando contenedor con nueva configuración..."
echo ""

read -p "   ¿Reiniciar contenedor ahora? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo "   🛑 Deteniendo contenedor..."
    docker-compose down
    
    echo "   🚀 Iniciando contenedor..."
    docker-compose up -d
    
    echo "   ⏳ Esperando 5 segundos para que inicie..."
    sleep 5
    
    echo ""
    echo "   🔍 Verificando conectividad después del reinicio:"
    
    if docker ps | grep -q evolution-api-checkin24hs; then
        echo "   ✅ Contenedor está corriendo"
        
        echo "   📡 Probando ping desde el contenedor:"
        docker exec evolution-api-checkin24hs ping -c 2 -W 3 web.whatsapp.com 2>&1 | tail -3
        
        echo ""
        echo "   🔍 Probando DNS:"
        docker exec evolution-api-checkin24hs nslookup web.whatsapp.com 2>&1 | grep -A 2 "Name:" | tail -1
    else
        echo -e "   ${RED}❌ Contenedor no se inició correctamente${NC}"
        echo "   Ver logs: docker-compose logs"
    fi
else
    echo "   ℹ️  Contenedor NO reiniciado"
    echo "   Ejecuta manualmente: cd /root/checkin24hs/evolution-api && docker-compose down && docker-compose up -d"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ docker-compose.yml actualizado con:"
echo "   - DNS: $SERVER_DNS, 8.8.8.8, 1.1.1.1"
echo "   - network_mode: bridge"
echo ""
echo "⚠️  Si el problema persiste:"
echo ""
echo "1. Verificar firewall:"
echo "   iptables -L OUTPUT -n -v"
echo ""
echo "2. Verificar si Docker tiene restricciones:"
echo "   cat /etc/docker/daemon.json"
echo ""
echo "3. Probar con network_mode: host (más permisivo):"
echo "   network_mode: host"
echo ""
echo "4. Ver logs del contenedor:"
echo "   docker logs evolution-api-checkin24hs"
echo ""
