#!/bin/bash
# Script para actualizar la IP del webmail en Traefik después de reiniciar el servicio

echo "🔍 Obteniendo IP actual del contenedor webmail..."

# Obtener IP actual del contenedor
WEBMAIL_IP=$(docker inspect $(docker ps | grep webmail | awk '{print $1}' | head -1) 2>/dev/null | grep -A 5 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4)

if [ -z "$WEBMAIL_IP" ]; then
    echo "❌ Error: No se pudo obtener la IP del contenedor webmail"
    echo "   Verifica que el servicio webmail esté corriendo: docker ps | grep webmail"
    exit 1
fi

echo "✅ IP actual del webmail: $WEBMAIL_IP"

# Hacer backup de la configuración
BACKUP_FILE="/etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/easypanel/traefik/config/main.yaml "$BACKUP_FILE"
echo "📦 Backup creado: $BACKUP_FILE"

# Actualizar configuración de Traefik
echo "🔧 Actualizando configuración de Traefik..."

# Reemplazar cualquier IP anterior (10.11.132.x)
sed -i "s|\"url\": \"http://10.11.132.[0-9]*:80/\"|\"url\": \"http://${WEBMAIL_IP}:80/\"|g" /etc/easypanel/traefik/config/main.yaml

# Reemplazar si todavía tiene el nombre del servicio
sed -i "s|\"url\": \"http://checkin24hs_webmail:80/\"|\"url\": \"http://${WEBMAIL_IP}:80/\"|g" /etc/easypanel/traefik/config/main.yaml

# Verificar que se actualizó
echo "✅ Verificando configuración actualizada..."
grep -A 5 '"checkin24hs_webmail-1":' /etc/easypanel/traefik/config/main.yaml | grep "url"

# Verificar conectividad desde Traefik
echo "🔍 Verificando conectividad desde Traefik..."
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    if docker exec "$TRAEFIK_CONTAINER" wget -qO- --timeout=5 "http://${WEBMAIL_IP}:80/" > /dev/null 2>&1; then
        echo "✅ Traefik puede alcanzar el webmail en $WEBMAIL_IP:80"
    else
        echo "⚠️  Advertencia: Traefik no pudo alcanzar el webmail (puede tardar unos segundos)"
    fi
fi

echo ""
echo "✅ ¡Configuración actualizada!"
echo "⏳ Espera 10-15 segundos para que Traefik recargue la configuración"
echo "🌐 Prueba: http://webmail.checkin24hs.com"

