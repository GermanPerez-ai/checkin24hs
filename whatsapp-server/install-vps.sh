#!/bin/bash

# 🌸 Script de Instalación Automática - WhatsApp Server en VPS
# Para Checkin24hs - Flor IA

set -e  # Salir si hay error

echo "🚀 Iniciando instalación de WhatsApp Server..."
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paso 1: Actualizar sistema
echo -e "${YELLOW}📦 Actualizando sistema...${NC}"
apt update
apt upgrade -y

# Paso 2: Instalar Node.js 20
echo -e "${YELLOW}📦 Instalando Node.js 20...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
else
    echo "✅ Node.js ya está instalado: $(node --version)"
fi

echo "✅ Node.js instalado: $(node --version)"
echo "✅ npm instalado: $(npm --version)"

# Paso 3: Instalar Chrome/Chromium
echo -e "${YELLOW}📦 Instalando Chromium y dependencias...${NC}"
apt install -y \
    chromium-browser \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    xdg-utils

echo "✅ Chromium instalado: $(which chromium-browser)"

# Paso 4: Instalar PM2
echo -e "${YELLOW}📦 Instalando PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
else
    echo "✅ PM2 ya está instalado"
fi

echo "✅ PM2 instalado: $(pm2 --version)"

# Paso 5: Verificar directorio
echo -e "${YELLOW}📁 Verificando directorio...${NC}"
if [ ! -f "whatsapp-server.js" ]; then
    echo "❌ Error: whatsapp-server.js no encontrado"
    echo "   Asegúrate de estar en el directorio whatsapp-server"
    exit 1
fi

echo "✅ Archivo whatsapp-server.js encontrado"

# Paso 6: Instalar dependencias
echo -e "${YELLOW}📦 Instalando dependencias de Node.js...${NC}"
npm install

echo "✅ Dependencias instaladas"

# Paso 7: Crear directorio de logs
echo -e "${YELLOW}📁 Creando directorio de logs...${NC}"
mkdir -p logs
echo "✅ Directorio de logs creado"

# Paso 8: Verificar archivo .env
echo -e "${YELLOW}⚙️ Verificando configuración...${NC}"
if [ ! -f ".env" ]; then
    echo "⚠️ Archivo .env no encontrado"
    echo "   Creando archivo .env con valores por defecto..."
    cat > .env << EOF
PORT=3001
INSTANCE_NUMBER=1
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
EOF
    echo "✅ Archivo .env creado"
    echo "⚠️ IMPORTANTE: Revisa y edita .env si necesitas cambiar valores"
else
    echo "✅ Archivo .env encontrado"
fi

# Paso 9: Configurar firewall
echo -e "${YELLOW}🔥 Configurando firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 3001/tcp
    ufw allow 3002/tcp
    ufw allow 3003/tcp
    ufw allow 3004/tcp
    echo "✅ Puertos 3001-3004 abiertos en firewall"
else
    echo "⚠️ ufw no está instalado, configura el firewall manualmente"
fi

echo ""
echo -e "${GREEN}✅ Instalación completada!${NC}"
echo ""
echo "📋 Próximos pasos:"
echo "1. Revisa el archivo .env: nano .env"
echo "2. Inicia las instancias:"
echo "   pm2 start ecosystem.config.js"
echo "   O manualmente:"
echo "   pm2 start whatsapp-server.js --name whatsapp-1 --env PORT=3001 --env INSTANCE_NUMBER=1"
echo "3. Ver logs: pm2 logs whatsapp-1"
echo "4. Guardar configuración: pm2 save"
echo ""
echo "🌐 Accede al panel web: http://TU_IP:3001"
echo ""

