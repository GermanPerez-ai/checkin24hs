#!/bin/bash

# ============================================
# SCRIPT: Corregir Bad Gateway - Dashboard
# ============================================
# Este script diagnostica y corrige el error "Bad Gateway"
# verificando el contenedor, la IP, y actualizando Traefik

echo "🔍 DIAGNÓSTICO: Bad Gateway - Dashboard"
echo "=========================================="
echo ""

# 1. Verificar que el contenedor del dashboard esté corriendo
echo "📋 Paso 1: Verificando contenedor del dashboard..."
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ ERROR: No se encontró el contenedor del dashboard corriendo"
    echo ""
    echo "📋 Contenedores relacionados con 'dashboard':"
    docker ps -a | grep dashboard
    echo ""
    echo "💡 Solución:"
    echo "   1. Ve a EasyPanel"
    echo "   2. Verifica que el servicio 'dashboard' esté activo"
    echo "   3. Si está detenido, inícialo desde EasyPanel"
    exit 1
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
echo ""

# 2. Verificar el estado del contenedor
echo "📋 Paso 2: Verificando estado del contenedor..."
CONTAINER_STATUS=$(docker inspect $DASHBOARD_CONTAINER --format='{{.State.Status}}')
echo "   Estado: $CONTAINER_STATUS"

if [ "$CONTAINER_STATUS" != "running" ]; then
    echo "❌ ERROR: El contenedor no está corriendo (estado: $CONTAINER_STATUS)"
    echo ""
    echo "💡 Intentando iniciar el contenedor..."
    docker start $DASHBOARD_CONTAINER
    sleep 5
    CONTAINER_STATUS=$(docker inspect $DASHBOARD_CONTAINER --format='{{.State.Status}}')
    if [ "$CONTAINER_STATUS" != "running" ]; then
        echo "❌ No se pudo iniciar el contenedor"
        exit 1
    fi
    echo "✅ Contenedor iniciado"
fi
echo ""

# 3. Obtener la IP del contenedor
echo "📋 Paso 3: Obteniendo IP del contenedor..."
DASHBOARD_IP=$(docker inspect $DASHBOARD_CONTAINER | grep -A 10 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)

if [ -z "$DASHBOARD_IP" ]; then
    echo "❌ ERROR: No se pudo obtener la IP del contenedor"
    echo ""
    echo "📋 Información del contenedor:"
    docker inspect $DASHBOARD_CONTAINER | grep -A 20 '"Networks"'
    exit 1
fi

echo "✅ IP del contenedor: $DASHBOARD_IP"
echo ""

# 4. Verificar en qué puerto está escuchando el contenedor
echo "📋 Paso 4: Verificando puerto del contenedor..."
CONTAINER_PORT=$(docker inspect $DASHBOARD_CONTAINER | grep -A 10 '"ExposedPorts"' | grep -o '"[0-9]*/tcp"' | head -1 | tr -d '"/tcp"')

if [ -z "$CONTAINER_PORT" ]; then
    # Intentar obtener el puerto de otra manera
    CONTAINER_PORT=$(docker port $DASHBOARD_CONTAINER 2>/dev/null | head -1 | cut -d':' -f2)
fi

# Si aún no encontramos el puerto, usar 3000 por defecto
if [ -z "$CONTAINER_PORT" ]; then
    echo "⚠️  No se pudo detectar el puerto, usando 3000 por defecto"
    CONTAINER_PORT=3000
else
    echo "✅ Puerto detectado: $CONTAINER_PORT"
fi
echo ""

# 5. Verificar que el contenedor esté respondiendo
echo "📋 Paso 5: Verificando que el contenedor responda..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${DASHBOARD_IP}:${CONTAINER_PORT}" || echo "000")

if [ "$RESPONSE" = "000" ] || [ "$RESPONSE" = "" ]; then
    echo "⚠️  El contenedor no responde en http://${DASHBOARD_IP}:${CONTAINER_PORT}"
    echo "   Esto puede ser normal si el servicio aún se está iniciando"
else
    echo "✅ El contenedor responde (código HTTP: $RESPONSE)"
fi
echo ""

# 6. Hacer backup de la configuración de Traefik
echo "📋 Paso 6: Haciendo backup de la configuración de Traefik..."
TRAEFIK_CONFIG="/etc/easypanel/traefik/config/main.yaml"
BACKUP_FILE="${TRAEFIK_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$TRAEFIK_CONFIG" ]; then
    echo "❌ ERROR: No se encontró el archivo de configuración de Traefik: $TRAEFIK_CONFIG"
    echo ""
    echo "💡 Buscando archivos de configuración alternativos..."
    find /etc/easypanel -name "*.yaml" -o -name "*.yml" 2>/dev/null | head -5
    exit 1
fi

cp "$TRAEFIK_CONFIG" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# 7. Actualizar la configuración de Traefik
echo "📋 Paso 7: Actualizando configuración de Traefik..."
echo "   Buscando URLs antiguas en la configuración..."

# Buscar todas las referencias al dashboard
OLD_URLS=$(grep -n "dashboard" "$TRAEFIK_CONFIG" | grep -i "url" || echo "")

if [ -n "$OLD_URLS" ]; then
    echo "   URLs encontradas:"
    echo "$OLD_URLS" | sed 's/^/      /'
fi

# Actualizar la configuración
sed -i "s|\"url\": \"http://10\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*/\"|\"url\": \"http://${DASHBOARD_IP}:${CONTAINER_PORT}/\"|g" "$TRAEFIK_CONFIG"
sed -i "s|\"url\": \"http://checkin24hs_dashboard:[0-9]*/\"|\"url\": \"http://${DASHBOARD_IP}:${CONTAINER_PORT}/\"|g" "$TRAEFIK_CONFIG"
sed -i "s|\"url\": \"http://dashboard:[0-9]*/\"|\"url\": \"http://${DASHBOARD_IP}:${CONTAINER_PORT}/\"|g" "$TRAEFIK_CONFIG"

echo "✅ Configuración actualizada con IP: $DASHBOARD_IP y puerto: $CONTAINER_PORT"
echo ""

# 8. Verificar los cambios
echo "📋 Paso 8: Verificando cambios en la configuración..."
NEW_URLS=$(grep -n "dashboard" "$TRAEFIK_CONFIG" | grep -i "url" || echo "")

if [ -n "$NEW_URLS" ]; then
    echo "   URLs actualizadas:"
    echo "$NEW_URLS" | sed 's/^/      /'
fi
echo ""

# 9. Reiniciar Traefik
echo "📋 Paso 9: Reiniciando Traefik..."
TRAEFIK_SERVICE=$(docker ps | grep traefik | awk '{print $1}' | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "⚠️  No se encontró el contenedor de Traefik corriendo"
    echo "   Intentando reiniciar el servicio de Traefik..."
    
    # Intentar reiniciar usando docker service (si está en modo swarm)
    docker service ls | grep traefik
    if [ $? -eq 0 ]; then
        TRAEFIK_SERVICE_NAME=$(docker service ls | grep traefik | awk '{print $2}' | head -1)
        if [ -n "$TRAEFIK_SERVICE_NAME" ]; then
            echo "   Reiniciando servicio de Traefik: $TRAEFIK_SERVICE_NAME"
            docker service update --force "$TRAEFIK_SERVICE_NAME"
        fi
    else
        echo "   Reiniciando contenedor de Traefik directamente..."
        docker restart $(docker ps -a | grep traefik | awk '{print $1}' | head -1)
    fi
else
    echo "   Reiniciando contenedor de Traefik: $TRAEFIK_SERVICE"
    docker restart $TRAEFIK_SERVICE
fi

echo "✅ Traefik reiniciado"
echo ""

# 10. Esperar y verificar
echo "📋 Paso 10: Esperando a que los servicios se estabilicen..."
echo "   ⏳ Espera 15-20 segundos..."
sleep 15

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Contenedor: $DASHBOARD_CONTAINER"
echo "   - IP: $DASHBOARD_IP"
echo "   - Puerto: $CONTAINER_PORT"
echo "   - URL configurada: http://${DASHBOARD_IP}:${CONTAINER_PORT}/"
echo "   - Backup: $BACKUP_FILE"
echo ""
echo "🔍 Próximos pasos:"
echo "   1. Abre https://dashboard.checkin24hs.com"
echo "   2. Si aún ves 'Bad Gateway', espera 30 segundos más y recarga"
echo "   3. Si el problema persiste, verifica los logs:"
echo "      docker logs $DASHBOARD_CONTAINER"
echo "      docker logs $(docker ps | grep traefik | awk '{print $1}' | head -1)"
echo ""

