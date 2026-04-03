#!/bin/bash

# Script para configurar HTTPS automáticamente para WhatsApp API
# Ejecutar como root en el servidor

set -e

echo "=========================================="
echo "CONFIGURACIÓN HTTPS PARA WHATSAPP API"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor ejecuta como root${NC}"
    exit 1
fi

echo -e "${YELLOW}Paso 1: Instalando Nginx y Certbot...${NC}"
apt update
apt install -y nginx certbot python3-certbot-nginx

echo ""
echo -e "${YELLOW}Paso 2: Creando configuración de Nginx...${NC}"

# Crear configuración de Nginx
cat > /etc/nginx/sites-available/api-whatsapp.conf << 'EOF'
# Proxy para WhatsApp API
server {
    listen 80;
    server_name api.checkin24hs.com;

    # Puerto 3001 (WhatsApp 1) - Ruta /api/1/
    location /api/1/ {
        rewrite ^/api/1/(.*) /$1 break;
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

    # Puerto 3002 (WhatsApp 2) - Ruta /api/2/
    location /api/2/ {
        rewrite ^/api/2/(.*) /$1 break;
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

    # Puerto 3003 (WhatsApp 3) - Ruta /api/3/
    location /api/3/ {
        rewrite ^/api/3/(.*) /$1 break;
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

    # Puerto 3004 (WhatsApp 4) - Ruta /api/4/
    location /api/4/ {
        rewrite ^/api/4/(.*) /$1 break;
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

    # Por defecto, usar puerto 3001 (compatibilidad)
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
EOF

echo -e "${GREEN}✅ Configuración creada${NC}"

echo ""
echo -e "${YELLOW}Paso 3: Activando configuración...${NC}"

# Activar configuración
ln -sf /etc/nginx/sites-available/api-whatsapp.conf /etc/nginx/sites-enabled/

# Verificar configuración
if nginx -t; then
    echo -e "${GREEN}✅ Configuración de Nginx válida${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✅ Nginx recargado${NC}"
else
    echo -e "${RED}❌ Error en configuración de Nginx${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Paso 4: Configurando firewall...${NC}"

# Abrir puertos si ufw está activo
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo -e "${GREEN}✅ Puertos 80 y 443 abiertos${NC}"
fi

echo ""
echo -e "${YELLOW}Paso 5: Obtener certificado SSL...${NC}"
echo ""
echo "⚠️  IMPORTANTE: Antes de continuar, asegúrate de que:"
echo "   1. El registro DNS 'api.checkin24hs.com' apunta a 72.61.58.240"
echo "   2. Han pasado al menos 5 minutos desde que agregaste el DNS"
echo ""
read -p "¿Ya configuraste el DNS y esperaste 5 minutos? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    read -p "Ingresa tu email para Let's Encrypt: " EMAIL
    
    certbot --nginx -d api.checkin24hs.com \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive \
        --redirect
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Certificado SSL obtenido correctamente${NC}"
        echo ""
        echo "=========================================="
        echo "✅ CONFIGURACIÓN COMPLETADA"
        echo "=========================================="
        echo ""
        echo "URL HTTPS: https://api.checkin24hs.com"
        echo ""
        echo "Próximos pasos:"
        echo "1. Actualiza la URL en el dashboard:"
        echo "   - Ve a Flor IA → WhatsApp"
        echo "   - Configuración → Cambia a: https://api.checkin24hs.com"
        echo ""
        echo "2. Verifica renovación automática:"
        echo "   certbot renew --dry-run"
    else
        echo -e "${RED}❌ Error al obtener certificado SSL${NC}"
        echo "Verifica que el DNS esté configurado correctamente"
    fi
else
    echo ""
    echo "⏸️  Configuración pausada"
    echo ""
    echo "Cuando estés listo, ejecuta:"
    echo "certbot --nginx -d api.checkin24hs.com --email tu-email@checkin24hs.com --agree-tos --non-interactive"
fi

echo ""
echo "=========================================="









