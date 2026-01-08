#!/bin/bash

echo "🔍 DIAGNÓSTICO COMPLETO DE BAD GATEWAY"
echo "========================================"
echo ""

# 1. Verificar IP del contenedor
echo "1️⃣ Verificando IP del contenedor del dashboard..."
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

DASHBOARD_IP=$(docker inspect $DASHBOARD_CONTAINER | grep -A 5 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "✅ Contenedor: $DASHBOARD_CONTAINER"
echo "✅ IP: $DASHBOARD_IP"
echo ""

# 2. Verificar que el contenedor está corriendo
echo "2️⃣ Verificando estado del contenedor..."
docker ps | grep $DASHBOARD_CONTAINER
echo ""

# 3. Verificar que el puerto 3000 está escuchando
echo "3️⃣ Verificando que el puerto 3000 está escuchando..."
docker exec $DASHBOARD_CONTAINER netstat -tuln 2>/dev/null | grep 3000 || docker exec $DASHBOARD_CONTAINER ss -tuln 2>/dev/null | grep 3000 || echo "⚠️ No se puede verificar (comando no disponible)"
echo ""

# 4. Verificar configuración de Traefik
echo "4️⃣ Verificando configuración de Traefik..."
TRAEFIK_CONFIG="/etc/easypanel/traefik/config/main.yaml"
if [ -f "$TRAEFIK_CONFIG" ]; then
    echo "📋 IPs configuradas en Traefik para dashboard:"
    grep -A 3 '"checkin24hs_dashboard-1":' $TRAEFIK_CONFIG | grep "url" || echo "⚠️ No se encontró configuración"
    echo ""
    
    # Verificar si la IP actual está en la configuración
    if grep -q "$DASHBOARD_IP" $TRAEFIK_CONFIG; then
        echo "✅ La IP $DASHBOARD_IP está en la configuración de Traefik"
    else
        echo "❌ La IP $DASHBOARD_IP NO está en la configuración de Traefik"
        echo "🔄 Actualizando configuración..."
        cp $TRAEFIK_CONFIG $TRAEFIK_CONFIG.backup.$(date +%Y%m%d_%H%M%S)
        sed -i "s|\"url\": \"http://10.11.132.[0-9]*:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" $TRAEFIK_CONFIG
        sed -i "s|\"url\": \"http://10.11.133.[0-9]*:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" $TRAEFIK_CONFIG
        sed -i "s|\"url\": \"http://checkin24hs_dashboard:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" $TRAEFIK_CONFIG
        echo "✅ Configuración actualizada"
    fi
else
    echo "❌ No se encontró el archivo de configuración de Traefik"
fi
echo ""

# 5. Verificar conectividad desde Traefik
echo "5️⃣ Verificando conectividad desde Traefik..."
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "🔍 Probando conexión desde Traefik a $DASHBOARD_IP:3000..."
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://${DASHBOARD_IP}:3000/ 2>&1 | head -5
    if [ $? -eq 0 ]; then
        echo "✅ Traefik puede conectarse al dashboard"
    else
        echo "❌ Traefik NO puede conectarse al dashboard"
    fi
else
    echo "⚠️ No se encontró el contenedor de Traefik"
fi
echo ""

# 6. Verificar logs de Traefik
echo "6️⃣ Últimos logs de Traefik relacionados con dashboard:"
docker logs traefik --tail 20 2>&1 | grep -i "dashboard\|checkin24hs" | tail -5
echo ""

# 7. Verificar logs del dashboard
echo "7️⃣ Últimos logs del dashboard:"
docker logs $DASHBOARD_CONTAINER --tail 10 2>&1
echo ""

# 8. Reiniciar Traefik si es necesario
echo "8️⃣ ¿Deseas reiniciar Traefik para aplicar cambios? (s/n)"
read -r response
if [[ "$response" =~ ^[Ss]$ ]]; then
    echo "🔄 Reiniciando Traefik..."
    docker service update --force traefik
    echo "✅ Traefik reiniciado. Espera 10-15 segundos..."
fi

echo ""
echo "✅ Diagnóstico completado"
echo "🌐 Verifica el dashboard en: https://dashboard.checkin24hs.com"

