#!/bin/bash

# Script SIMPLE para configurar HTTPS para WhatsApp API
# Usa subdominios separados para cada puerto (más fácil)

set -e

echo "=========================================="
echo "CONFIGURACIÓN HTTPS SIMPLE"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Ejecuta como root${NC}"
    exit 1
fi

echo -e "${YELLOW}Paso 1: Instalando Nginx y Certbot...${NC}"
apt update -qq
apt install -y nginx certbot python3-certbot-nginx > /dev/null 2>&1

echo -e "${GREEN}✅ Instalado${NC}"

echo ""
echo -e "${YELLOW}Paso 2: Creando configuración de Nginx...${NC}"

# Configuración simple: un dominio por puerto
cat > /etc/nginx/sites-available/whatsapp-api.conf << 'EOF'
# WhatsApp API - Puerto 3001
server {
    listen 80;
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
    listen 80;
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
    listen 80;
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
    listen 80;
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

# Activar
ln -sf /etc/nginx/sites-available/whatsapp-api.conf /etc/nginx/sites-enabled/

# Verificar y recargar
if nginx -t > /dev/null 2>&1; then
    systemctl reload nginx
    echo -e "${GREEN}✅ Nginx configurado${NC}"
else
    echo -e "${RED}❌ Error en configuración${NC}"
    nginx -t
    exit 1
fi

# Abrir puertos
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
fi

echo ""
echo -e "${YELLOW}Paso 3: Configurar DNS${NC}"
echo ""
echo "⚠️  IMPORTANTE: Agrega estos registros DNS en Hostinger:"
echo ""
echo "Tipo: A | Nombre: api1 | Apunta a: 72.61.58.240 | TTL: 14400"
echo "Tipo: A | Nombre: api2 | Apunta a: 72.61.58.240 | TTL: 14400"
echo "Tipo: A | Nombre: api3 | Apunta a: 72.61.58.240 | TTL: 14400"
echo "Tipo: A | Nombre: api4 | Apunta a: 72.61.58.240 | TTL: 14400"
echo ""
read -p "¿Ya agregaste los DNS y esperaste 5 minutos? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    read -p "Email para Let's Encrypt: " EMAIL
    
    echo ""
    echo -e "${YELLOW}Obteniendo certificados SSL...${NC}"
    
    certbot --nginx -d api1.checkin24hs.com,api2.checkin24hs.com,api3.checkin24hs.com,api4.checkin24hs.com \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive \
        --redirect
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ HTTPS configurado correctamente${NC}"
        echo ""
        echo "URLs HTTPS disponibles:"
        echo "  - https://api1.checkin24hs.com (puerto 3001)"
        echo "  - https://api2.checkin24hs.com (puerto 3002)"
        echo "  - https://api3.checkin24hs.com (puerto 3003)"
        echo "  - https://api4.checkin24hs.com (puerto 3004)"
        echo ""
        echo "Próximo paso: Actualizar el dashboard para usar estas URLs"
    else
        echo -e "${RED}❌ Error al obtener certificados${NC}"
    fi
else
    echo ""
    echo "Cuando estés listo, ejecuta:"
    echo "certbot --nginx -d api1.checkin24hs.com,api2.checkin24hs.com,api3.checkin24hs.com,api4.checkin24hs.com --email tu-email@checkin24hs.com --agree-tos --non-interactive"
fi









