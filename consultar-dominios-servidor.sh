#!/bin/bash

echo "=========================================="
echo "🔍 CONSULTANDO DOMINIOS HABILITADOS"
echo "=========================================="
echo ""

# Verificar si Nginx está instalado
if command -v nginx &> /dev/null; then
    echo "✅ Nginx está instalado"
    echo ""
    
    echo "📋 Dominios configurados en Nginx:"
    echo "-----------------------------------"
    
    # Listar sitios disponibles
    if [ -d "/etc/nginx/sites-available" ]; then
        echo ""
        echo "Sitios disponibles:"
        ls -la /etc/nginx/sites-available/ | grep -v "^d" | grep -v "total" | awk '{print $9}' | grep -v "^$" | grep -v "default"
    fi
    
    # Listar sitios habilitados
    if [ -d "/etc/nginx/sites-enabled" ]; then
        echo ""
        echo "Sitios habilitados:"
        ls -la /etc/nginx/sites-enabled/ | grep -v "^d" | grep -v "total" | awk '{print $9}' | grep -v "^$" | grep -v "default"
    fi
    
    # Extraer server_name de cada configuración
    echo ""
    echo "📝 Dominios configurados (server_name):"
    echo "-----------------------------------"
    if [ -d "/etc/nginx/sites-enabled" ]; then
        for file in /etc/nginx/sites-enabled/*; do
            if [ -f "$file" ]; then
                echo ""
                echo "Archivo: $(basename $file)"
                grep -E "server_name|listen" "$file" | grep -v "^#" | head -5
            fi
        done
    fi
    
    # Verificar puertos en uso
    echo ""
    echo "🔌 Puertos en uso por Nginx:"
    echo "-----------------------------------"
    sudo netstat -tlnp | grep nginx | awk '{print $4}' | sort -u
else
    echo "⚠️ Nginx no está instalado"
fi

echo ""
echo "=========================================="
echo "🔐 CERTIFICADOS SSL (Let's Encrypt)"
echo "=========================================="
echo ""

# Verificar si Certbot está instalado
if command -v certbot &> /dev/null; then
    echo "✅ Certbot está instalado"
    echo ""
    
    if [ -d "/etc/letsencrypt/live" ]; then
        echo "📋 Certificados SSL activos:"
        echo "-----------------------------------"
        ls -la /etc/letsencrypt/live/ | grep "^d" | awk '{print $9}' | grep -v "^$" | grep -v "README"
        
        echo ""
        echo "📅 Detalles de certificados:"
        echo "-----------------------------------"
        for domain in /etc/letsencrypt/live/*/; do
            if [ -d "$domain" ] && [ "$(basename $domain)" != "README" ]; then
                echo ""
                echo "Dominio: $(basename $domain)"
                if [ -f "$domain/cert.pem" ]; then
                    echo "  Válido hasta: $(sudo openssl x509 -in "$domain/cert.pem" -noout -enddate | cut -d= -f2)"
                    echo "  Emisor: $(sudo openssl x509 -in "$domain/cert.pem" -noout -issuer | cut -d= -f2- | sed 's/^[[:space:]]*//')"
                fi
            fi
        done
    else
        echo "⚠️ No hay certificados SSL configurados"
    fi
else
    echo "⚠️ Certbot no está instalado"
fi

echo ""
echo "=========================================="
echo "🌐 CONFIGURACIONES DE DNS (si aplica)"
echo "=========================================="
echo ""

# Verificar IP pública del servidor
echo "📍 IP pública del servidor:"
curl -s ifconfig.me
echo ""
echo ""

# Verificar hosts locales
if [ -f "/etc/hosts" ]; then
    echo "📋 Entradas en /etc/hosts:"
    echo "-----------------------------------"
    grep -v "^#" /etc/hosts | grep -v "^$" | head -10
fi

echo ""
echo "=========================================="
echo "🔍 SERVICIOS WEB ACTIVOS"
echo "=========================================="
echo ""

# Verificar servicios web corriendo
echo "Servicios escuchando en puertos comunes:"
echo "-----------------------------------"
echo "Puerto 80 (HTTP):"
sudo netstat -tlnp | grep ":80 " | head -3
echo ""
echo "Puerto 443 (HTTPS):"
sudo netstat -tlnp | grep ":443 " | head -3
echo ""
echo "Puertos 3000-3010 (aplicaciones):"
sudo netstat -tlnp | grep -E ":300[0-9] |:3010 " | head -10

echo ""
echo "=========================================="
echo "✅ CONSULTA COMPLETADA"
echo "=========================================="

