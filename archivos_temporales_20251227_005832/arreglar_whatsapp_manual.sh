#!/bin/bash

echo "=========================================="
echo "🔧 Configuración Manual de WhatsApp"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar estado actual
echo "📊 Paso 1: Verificar estado actual de PM2"
echo "----------------------------------------"
pm2 list | grep -E "whatsapp|dashboard" || echo "No hay servicios de WhatsApp en PM2"
echo ""

# 2. Verificar puertos
echo "🔌 Paso 2: Verificar puertos en uso"
echo "----------------------------------------"
for port in 3001 3002 3003 3004; do
    if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✅ Puerto $port está en uso${NC}"
        netstat -tulpn 2>/dev/null | grep ":$port " || ss -tulpn 2>/dev/null | grep ":$port "
    else
        echo -e "${RED}❌ Puerto $port NO está en uso${NC}"
    fi
done
echo ""

# 3. Verificar logs de PM2
echo "📋 Paso 3: Verificar logs de WhatsApp-1"
echo "----------------------------------------"
if pm2 describe whatsapp-1 &>/dev/null; then
    echo "Últimas 20 líneas de logs:"
    pm2 logs whatsapp-1 --lines 20 --nostream 2>&1 | tail -20
else
    echo -e "${RED}❌ whatsapp-1 no existe en PM2${NC}"
fi
echo ""

# 4. Verificar archivos
echo "📁 Paso 4: Verificar archivos de WhatsApp"
echo "----------------------------------------"
cd ~/checkin24hs/whatsapp-server 2>/dev/null || cd /root/checkin24hs/whatsapp-server 2>/dev/null || { echo "❌ No se encontró el directorio whatsapp-server"; exit 1; }

if [ -f "whatsapp-server.js" ]; then
    echo -e "${GREEN}✅ whatsapp-server.js existe${NC}"
else
    echo -e "${RED}❌ whatsapp-server.js NO existe${NC}"
    exit 1
fi

if [ -f "ecosystem.config.js" ]; then
    echo -e "${GREEN}✅ ecosystem.config.js existe${NC}"
else
    echo -e "${RED}❌ ecosystem.config.js NO existe${NC}"
    exit 1
fi

# Verificar que el servidor escuche en 0.0.0.0
echo ""
echo "🔍 Verificando configuración del servidor..."
if grep -q "server.listen(CONFIG.PORT" whatsapp-server.js; then
    echo -e "${YELLOW}⚠️  El servidor puede no estar escuchando en todas las interfaces${NC}"
    echo "Necesitamos verificar que escuche en 0.0.0.0"
fi
echo ""

# 5. Detener servicios existentes
echo "🛑 Paso 5: Detener servicios existentes"
echo "----------------------------------------"
pm2 stop whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4 2>/dev/null
pm2 delete whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4 2>/dev/null
echo "✅ Servicios detenidos"
echo ""

# 6. Verificar que el servidor escuche en 0.0.0.0
echo "🔧 Paso 6: Asegurar que el servidor escuche en 0.0.0.0"
echo "----------------------------------------"
if ! grep -q "server.listen(CONFIG.PORT, '0.0.0.0'" whatsapp-server.js; then
    echo "Corrigiendo configuración del servidor..."
    sed -i "s/server.listen(CONFIG.PORT/server.listen(CONFIG.PORT, '0.0.0.0'/g" whatsapp-server.js
    echo -e "${GREEN}✅ Configuración corregida${NC}"
else
    echo -e "${GREEN}✅ El servidor ya está configurado correctamente${NC}"
fi
echo ""

# 7. Verificar dependencias
echo "📦 Paso 7: Verificar dependencias"
echo "----------------------------------------"
if [ -f "package.json" ]; then
    if [ ! -d "node_modules" ]; then
        echo "Instalando dependencias..."
        npm install
    else
        echo -e "${GREEN}✅ node_modules existe${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  package.json no encontrado, continuando...${NC}"
fi
echo ""

# 8. Iniciar servicios manualmente con PM2
echo "🚀 Paso 8: Iniciar servicios WhatsApp con PM2"
echo "----------------------------------------"
echo "Iniciando whatsapp-1 en puerto 3001..."
pm2 start ecosystem.config.js --only whatsapp-1
sleep 2

echo "Iniciando whatsapp-2 en puerto 3002..."
pm2 start ecosystem.config.js --only whatsapp-2
sleep 2

echo "Iniciando whatsapp-3 en puerto 3003..."
pm2 start ecosystem.config.js --only whatsapp-3
sleep 2

echo "Iniciando whatsapp-4 en puerto 3004..."
pm2 start ecosystem.config.js --only whatsapp-4
sleep 2

echo ""
echo "✅ Servicios iniciados"
echo ""

# 9. Verificar estado
echo "✅ Paso 9: Verificar estado final"
echo "----------------------------------------"
pm2 list | grep whatsapp
echo ""

# 10. Verificar puertos
echo "🔌 Verificando puertos..."
for port in 3001 3002 3003 3004; do
    if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✅ Puerto $port está activo${NC}"
        # Verificar que escuche en 0.0.0.0
        if netstat -tulpn 2>/dev/null | grep ":$port " | grep -q "0.0.0.0" || ss -tulpn 2>/dev/null | grep ":$port " | grep -q "0.0.0.0"; then
            echo -e "   ${GREEN}✅ Escuchando en todas las interfaces (0.0.0.0)${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Puede no estar escuchando en todas las interfaces${NC}"
        fi
    else
        echo -e "${RED}❌ Puerto $port NO está activo${NC}"
    fi
done
echo ""

# 11. Mostrar logs recientes
echo "📋 Paso 10: Logs recientes de WhatsApp-1"
echo "----------------------------------------"
pm2 logs whatsapp-1 --lines 15 --nostream 2>&1 | tail -15
echo ""

# 12. Probar acceso
echo "🌐 Paso 11: Probar acceso a los servicios"
echo "----------------------------------------"
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "IP del servidor: $HOST_IP"
echo ""

for port in 3001 3002 3003 3004; do
    echo -n "Probando puerto $port... "
    if curl -s --max-time 3 "http://$HOST_IP:$port/api/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Funciona${NC}"
    else
        echo -e "${RED}❌ No responde${NC}"
    fi
done
echo ""

# 13. Guardar configuración de PM2
echo "💾 Paso 12: Guardar configuración de PM2"
echo "----------------------------------------"
pm2 save
echo -e "${GREEN}✅ Configuración guardada${NC}"
echo ""

echo "=========================================="
echo "✅ Configuración manual completada"
echo "=========================================="
echo ""
echo "📱 Próximos pasos:"
echo "1. Verifica los logs con: pm2 logs whatsapp-1"
echo "2. Accede al dashboard y configura la URL: http://$HOST_IP"
echo "3. Conecta cada instancia de WhatsApp desde el dashboard"
echo ""

