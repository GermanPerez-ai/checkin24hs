#!/bin/bash
# Script para actualizar la IP del dashboard en Traefik después de reiniciar el servicio

echo "🔍 Obteniendo IP actual del contenedor dashboard..."

# Obtener IP actual del contenedor
DASHBOARD_IP=$(docker inspect $(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1) 2>/dev/null | grep -A 5 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4)

if [ -z "$DASHBOARD_IP" ]; then
    echo "❌ Error: No se pudo obtener la IP del contenedor dashboard"
    echo "   Verifica que el servicio dashboard esté corriendo: docker ps | grep dashboard"
    exit 1
fi

echo "✅ IP actual del dashboard: $DASHBOARD_IP"

# Hacer backup de la configuración
BACKUP_FILE="/etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/easypanel/traefik/config/main.yaml "$BACKUP_FILE"
echo "📦 Backup creado: $BACKUP_FILE"

# Actualizar configuración de Traefik
echo "🔧 Actualizando configuración de Traefik..."

# Reemplazar cualquier IP anterior (10.11.132.x) para dashboard
sed -i "s|\"url\": \"http://10.11.132.[0-9]*:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" /etc/easypanel/traefik/config/main.yaml

# Reemplazar si todavía tiene el nombre del servicio
sed -i "s|\"url\": \"http://checkin24hs_dashboard:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" /etc/easypanel/traefik/config/main.yaml

# Verificar que se actualizó
echo "✅ Verificando configuración actualizada..."
grep -A 5 '"checkin24hs_dashboard-1":' /etc/easypanel/traefik/config/main.yaml | grep "url"

# Verificar conectividad desde Traefik
echo "🔍 Verificando conectividad desde Traefik..."
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    if docker exec "$TRAEFIK_CONTAINER" wget -qO- --timeout=5 "http://${DASHBOARD_IP}:3000/" > /dev/null 2>&1; then
        echo "✅ Traefik puede alcanzar el dashboard en $DASHBOARD_IP:3000"
    else
        echo "⚠️  Advertencia: Traefik no pudo alcanzar el dashboard (puede tardar unos segundos)"
    fi
fi

echo ""
echo "✅ ¡Configuración actualizada!"
echo "⏳ Espera 10-15 segundos para que Traefik recargue la configuración"
echo "🌐 Prueba: http://dashboard.checkin24hs.com"

