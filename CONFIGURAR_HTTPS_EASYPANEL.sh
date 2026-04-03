#!/bin/bash

# Script para configurar HTTPS considerando EasyPanel
# Verifica si hay conflictos con el puerto 80

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "CONFIGURACIÓN HTTPS PARA WHATSAPP API"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Ejecuta como root${NC}"
    exit 1
fi

# Verificar si hay algo usando el puerto 80
echo -e "${YELLOW}Verificando puerto 80...${NC}"
if lsof -i :80 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  El puerto 80 está en uso${NC}"
    echo ""
    echo "Opciones:"
    echo "1. Usar Traefik de EasyPanel (recomendado si está disponible)"
    echo "2. Configurar Nginx en puerto alternativo"
    echo "3. Detener el servicio que usa el puerto 80 temporalmente"
    echo ""
    read -p "¿Qué servicio está usando el puerto 80? (traefik/nginx/otro): " SERVICE
    
    if [ "$SERVICE" = "traefik" ]; then
        echo ""
        echo -e "${BLUE}Opción recomendada: Usar Traefik de EasyPanel${NC}"
        echo ""
        echo "Traefik ya maneja HTTPS. Solo necesitas:"
        echo "1. Agregar los subdominios en EasyPanel → Dominios"
        echo "2. Configurar que apunten a los puertos 3001-3004"
        echo ""
        echo "¿Quieres que te muestre cómo configurarlo en EasyPanel? (s/n)"
        read -n 1 -r
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            echo ""
            echo "Pasos en EasyPanel:"
            echo "1. Ve a cada servicio (whatsapp, whatsapp2, whatsapp3, whatsapp4)"
            echo "2. Ve a la sección 'Dominios'"
            echo "3. Agrega dominio:"
            echo "   - whatsapp: api1.checkin24hs.com"
            echo "   - whatsapp2: api2.checkin24hs.com"
            echo "   - whatsapp3: api3.checkin24hs.com"
            echo "   - whatsapp4: api4.checkin24hs.com"
            echo "4. Activa SSL/TLS en cada dominio"
            echo ""
            echo "EasyPanel configurará HTTPS automáticamente con Let's Encrypt"
            exit 0
        fi
    fi
fi

echo ""
echo -e "${YELLOW}Instalando Nginx y Certbot...${NC}"
apt update -qq
apt install -y nginx certbot python3-certbot-nginx > /dev/null 2>&1

echo -e "${GREEN}✅ Instalado${NC}"

echo ""
echo -e "${YELLOW}Creando configuración...${NC}"

cat > /etc/nginx/sites-available/whatsapp-api.conf << 'EOF'
# WhatsApp API - Puerto 3001
server {
    listen 8080;
    server_name api1.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# WhatsApp API - Puerto 3002
server {
    listen 8080;
    server_name api2.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# WhatsApp API - Puerto 3003
server {
    listen 8080;
    server_name api3.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# WhatsApp API - Puerto 3004
server {
    listen 8080;
    server_name api4.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/whatsapp-api.conf /etc/nginx/sites-enabled/

if nginx -t > /dev/null 2>&1; then
    systemctl reload nginx
    echo -e "${GREEN}✅ Nginx configurado en puerto 8080${NC}"
else
    echo -e "${RED}❌ Error${NC}"
    nginx -t
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "Nginx está configurado en el puerto 8080 para evitar conflictos."
echo ""
echo "Opciones para HTTPS:"
echo ""
echo "1. Usar EasyPanel/Traefik (RECOMENDADO):"
echo "   - Agrega dominios api1-4.checkin24hs.com en EasyPanel"
echo "   - EasyPanel manejará HTTPS automáticamente"
echo ""
echo "2. Configurar Nginx en puerto 80 (si no hay conflicto):"
echo "   - Cambia 'listen 8080' a 'listen 80' en la configuración"
echo "   - Luego ejecuta certbot"
echo ""
echo "¿Quieres usar EasyPanel o configurar Nginx directamente? (easypanel/nginx)"
read -r OPTION

if [ "$OPTION" = "easypanel" ]; then
    echo ""
    echo "Perfecto. Configura en EasyPanel:"
    echo "1. Ve a cada servicio WhatsApp"
    echo "2. Agrega dominio con SSL activado"
    echo "3. EasyPanel configurará HTTPS automáticamente"
else
    echo ""
    echo "Agrega estos DNS en Hostinger:"
    echo "api1.checkin24hs.com → 72.61.58.240"
    echo "api2.checkin24hs.com → 72.61.58.240"
    echo "api3.checkin24hs.com → 72.61.58.240"
    echo "api4.checkin24hs.com → 72.61.58.240"
    echo ""
    read -p "¿Ya agregaste los DNS? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        read -p "Email: " EMAIL
        certbot --nginx -d api1.checkin24hs.com,api2.checkin24hs.com,api3.checkin24hs.com,api4.checkin24hs.com \
            --email "$EMAIL" --agree-tos --non-interactive --redirect
    fi
fi









