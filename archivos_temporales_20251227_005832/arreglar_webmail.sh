#!/bin/bash

echo "=========================================="
echo "📧 ARREGLAR WEBMAIL - webmail.checkin24hs.com"
echo "=========================================="
echo ""

# 1. Verificar servicios webmail
echo "1️⃣ Verificando servicios webmail..."
WEBMAIL_SERVICE=$(docker ps | grep -i webmail | head -1 | awk '{print $1}')
ROUNDCUBE_SERVICE=$(docker ps | grep -i roundcube | head -1 | awk '{print $1}')

if [ -z "$WEBMAIL_SERVICE" ] && [ -z "$ROUNDCUBE_SERVICE" ]; then
    echo "❌ No se encontraron servicios webmail corriendo"
    echo ""
    echo "Buscando en Docker Swarm..."
    docker service ls | grep -i webmail
    docker service ls | grep -i roundcube
    echo ""
    echo "Si hay servicios en Swarm, intenta:"
    echo "  docker service update --force <nombre_servicio>"
    exit 1
fi

# 2. Ver logs
echo "2️⃣ Verificando logs del servicio..."
if [ -n "$WEBMAIL_SERVICE" ]; then
    echo "Logs de webmail:"
    docker logs "$WEBMAIL_SERVICE" --tail 20
elif [ -n "$ROUNDCUBE_SERVICE" ]; then
    echo "Logs de roundcube:"
    docker logs "$ROUNDCUBE_SERVICE" --tail 20
fi
echo ""

# 3. Verificar configuración Traefik
echo "3️⃣ Verificando configuración Traefik..."
WEBMAIL_CONFIG=$(grep -A 10 -i "webmail\|roundcube" /etc/easypanel/traefik/config/main.yaml 2>/dev/null)

if [ -z "$WEBMAIL_CONFIG" ]; then
    echo "⚠️ No se encontró configuración en Traefik para webmail"
    echo ""
    echo "Buscando en todos los archivos de Traefik..."
    find /etc/easypanel/traefik -type f -exec grep -l "webmail\|roundcube" {} \; 2>/dev/null
else
    echo "Configuración encontrada:"
    echo "$WEBMAIL_CONFIG"
fi
echo ""

# 4. Verificar acceso local
echo "4️⃣ Probando acceso local..."
if [ -n "$WEBMAIL_SERVICE" ]; then
    docker exec "$WEBMAIL_SERVICE" wget -qO- http://localhost/ 2>&1 | head -5
elif [ -n "$ROUNDCUBE_SERVICE" ]; then
    docker exec "$ROUNDCUBE_SERVICE" wget -qO- http://localhost/ 2>&1 | head -5
fi
echo ""

# 5. Verificar red
echo "5️⃣ Verificando red Docker..."
docker network ls | grep -i easypanel
echo ""

# 6. Soluciones sugeridas
echo "=========================================="
echo "🔧 SOLUCIONES SUGERIDAS"
echo "=========================================="
echo ""
echo "Si el servicio está corriendo pero no accesible:"
echo "1. Reiniciar el servicio:"
if [ -n "$WEBMAIL_SERVICE" ]; then
    echo "   docker restart $WEBMAIL_SERVICE"
elif [ -n "$ROUNDCUBE_SERVICE" ]; then
    echo "   docker restart $ROUNDCUBE_SERVICE"
fi
echo ""
echo "2. Reiniciar Traefik:"
echo "   docker service update --force traefik"
echo ""
echo "3. Verificar que el servicio esté en la red correcta:"
echo "   docker network inspect easypanel | grep -A 5 webmail"
echo ""

