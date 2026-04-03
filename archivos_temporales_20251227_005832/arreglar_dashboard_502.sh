#!/bin/bash

echo "=========================================="
echo "🔧 Solución: Bad Gateway (502) Dashboard"
echo "=========================================="
echo ""

# 1. Verificar que el dashboard esté corriendo
echo "=== 1. Verificando estado del dashboard ==="
DASHBOARD_STATUS=$(pm2 list | grep dashboard | awk '{print $10}')
if [ "$DASHBOARD_STATUS" != "online" ]; then
    echo "⚠️ Dashboard no está online, iniciando..."
    pm2 restart dashboard
    sleep 3
else
    echo "✅ Dashboard está online"
fi
echo ""

# 2. Verificar puerto 3010
echo "=== 2. Verificando puerto 3010 ==="
if netstat -tulpn 2>/dev/null | grep -q ":3010 " || ss -tulpn 2>/dev/null | grep -q ":3010 "; then
    echo "✅ Puerto 3010 está activo"
else
    echo "❌ Puerto 3010 NO está activo"
    echo "Revisando configuración del servidor..."
    
    # Verificar que server.js esté configurado para el puerto 3010
    if grep -q "PORT.*3010\|PORT.*=.*3010" ~/checkin24hs/server.js; then
        echo "✅ server.js configurado para puerto 3010"
    else
        echo "⚠️ server.js puede no estar configurado correctamente"
        echo "Verificando..."
        grep -n "PORT\|listen" ~/checkin24hs/server.js | head -3
    fi
    
    echo "Reiniciando dashboard..."
    pm2 restart dashboard
    sleep 5
fi
echo ""

# 3. Verificar configuración de Traefik
echo "=== 3. Verificando configuración de Traefik ==="
if [ -f /etc/easypanel/traefik/config/main.yaml ]; then
    CURRENT_URL=$(grep -A 5 "checkin24hs_dashboard-1" /etc/easypanel/traefik/config/main.yaml | grep "url:" | head -1 | sed 's/.*"url": "\([^"]*\)".*/\1/')
    echo "URL actual en Traefik: $CURRENT_URL"
    
    if [ "$CURRENT_URL" != "http://72.61.58.240:3010" ]; then
        echo "⚠️ URL incorrecta, corrigiendo..."
        sed -i 's|"url": "http://checkin24hs_dashboard:80/"|"url": "http://72.61.58.240:3010"|g' /etc/easypanel/traefik/config/main.yaml
        sed -i 's|"url": "http://72.61.58.240:3000"|"url": "http://72.61.58.240:3010"|g' /etc/easypanel/traefik/config/main.yaml
        
        # Verificar cambio
        NEW_URL=$(grep -A 5 "checkin24hs_dashboard-1" /etc/easypanel/traefik/config/main.yaml | grep "url:" | head -1 | sed 's/.*"url": "\([^"]*\)".*/\1/')
        echo "✅ URL actualizada a: $NEW_URL"
        
        # Reiniciar Traefik
        echo "Reiniciando Traefik..."
        docker service update --force traefik
        sleep 5
    else
        echo "✅ URL correcta en Traefik"
    fi
else
    echo "❌ Archivo de configuración de Traefik no encontrado"
fi
echo ""

# 4. Probar acceso
echo "=== 4. Probando acceso ==="
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Probando http://$HOST_IP:3010..."
if curl -s --max-time 3 "http://$HOST_IP:3010" > /dev/null 2>&1; then
    echo "✅ Dashboard responde correctamente"
else
    echo "❌ Dashboard NO responde"
    echo "Revisando logs..."
    pm2 logs dashboard --lines 10 --nostream 2>&1 | tail -10
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Prueba acceder a: https://dashboard.checkin24hs.com"
echo "Si aún hay problemas, ejecuta: pm2 logs dashboard"

