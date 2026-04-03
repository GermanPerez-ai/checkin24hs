#!/bin/bash
# Script para diagnosticar error 503 en webmail
# Ejecuta este script en el servidor donde está desplegado el webmail

echo "========================================"
echo "🔍 Diagnóstico de Error 503"
echo "========================================"
echo ""

# Verificar configuración de Nginx
echo "📋 Verificando configuración de Nginx..."
echo ""

NGINX_CONFIG="/etc/nginx/sites-available/webmail.checkin24hs.com"
if [ -f "$NGINX_CONFIG" ]; then
    echo "✅ Archivo de configuración encontrado"
    echo ""
    
    # Buscar proxy_pass
    if grep -q "proxy_pass" "$NGINX_CONFIG"; then
        echo "🔗 Proxy encontrado:"
        grep "proxy_pass" "$NGINX_CONFIG" | sed 's/^/   /'
        
        # Extraer puerto
        PORT=$(grep "proxy_pass" "$NGINX_CONFIG" | grep -oE ':[0-9]+' | head -1 | tr -d ':')
        if [ ! -z "$PORT" ]; then
            echo "   Puerto configurado: $PORT"
            echo ""
            echo "🔌 Verificando puerto $PORT..."
            
            if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
                echo "✅ Puerto $PORT está en uso"
            else
                echo "❌ Puerto $PORT NO está en uso"
                echo "   El servicio backend no está corriendo"
            fi
        fi
    fi
    
    # Buscar fastcgi_pass (PHP)
    if grep -q "fastcgi_pass" "$NGINX_CONFIG"; then
        echo ""
        echo "🔗 PHP-FPM encontrado:"
        grep "fastcgi_pass" "$NGINX_CONFIG" | sed 's/^/   /'
        
        echo ""
        echo "🐘 Verificando PHP-FPM..."
        
        PHP_SERVICES=("php8.1-fpm" "php8.0-fpm" "php7.4-fpm" "php-fpm")
        PHP_RUNNING=false
        
        for service in "${PHP_SERVICES[@]}"; do
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                echo "✅ $service está corriendo"
                PHP_RUNNING=true
                break
            fi
        done
        
        if [ "$PHP_RUNNING" = false ]; then
            echo "❌ PHP-FPM NO está corriendo"
            echo "   Ejecuta: sudo systemctl start php8.1-fpm"
        fi
    fi
else
    echo "⚠️  Archivo de configuración no encontrado en: $NGINX_CONFIG"
    echo "   Buscando en otras ubicaciones..."
    
    # Buscar en otras ubicaciones comunes
    for config in /etc/nginx/conf.d/webmail.conf /etc/nginx/sites-enabled/webmail.checkin24hs.com; do
        if [ -f "$config" ]; then
            echo "✅ Encontrado en: $config"
            NGINX_CONFIG="$config"
            break
        fi
    done
fi

echo ""
echo "📡 Verificando puertos comunes..."
echo ""

COMMON_PORTS=(80 443 8080 3000 9000)
for port in "${COMMON_PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✅ Puerto $port : En uso"
    else
        echo "⚠️  Puerto $port : No en uso"
    fi
done

echo ""
echo "🐳 Verificando contenedores Docker..."
echo ""

if command -v docker &> /dev/null; then
    DOCKER_CONTAINERS=$(docker ps -a 2>/dev/null | grep -iE "webmail|roundcube|mail")
    if [ ! -z "$DOCKER_CONTAINERS" ]; then
        echo "✅ Contenedores encontrados:"
        echo "$DOCKER_CONTAINERS" | sed 's/^/   /'
    else
        echo "⚠️  No se encontraron contenedores de webmail"
    fi
else
    echo "⚠️  Docker no está instalado o no está en el PATH"
fi

echo ""
echo "📝 Verificando logs de Nginx..."
echo ""

ERROR_LOG="/var/log/nginx/webmail-error.log"
if [ -f "$ERROR_LOG" ]; then
    echo "📄 Últimas líneas del log de errores:"
    echo ""
    tail -10 "$ERROR_LOG" 2>/dev/null | while IFS= read -r line; do
        if echo "$line" | grep -qE "503|Connection refused|upstream"; then
            echo "   $line" | sed 's/.*/\x1b[31m&\x1b[0m/'
        else
            echo "   $line"
        fi
    done
else
    echo "⚠️  Log de errores no encontrado: $ERROR_LOG"
    echo "   Verifica: sudo tail -f /var/log/nginx/error.log"
fi

echo ""
echo "========================================"
echo "📋 Resumen y Próximos Pasos"
echo "========================================"
echo ""
echo "1. Si el puerto no está en uso:"
echo "   - Inicia el servicio backend (Node.js, Docker, etc.)"
echo ""
echo "2. Si PHP-FPM no está corriendo:"
echo "   sudo systemctl start php8.1-fpm"
echo "   sudo systemctl enable php8.1-fpm"
echo ""
echo "3. Verifica los logs para más detalles:"
echo "   sudo tail -f /var/log/nginx/webmail-error.log"
echo ""
echo "4. Consulta SOLUCION_ERROR_503.md para más detalles"
echo ""

