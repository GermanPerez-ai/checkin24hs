#!/bin/bash

echo "=========================================="
echo "🔍 Diagnóstico de Bad Gateway"
echo "=========================================="
echo ""

# 1. Verificar estado de PM2
echo "1. Estado de PM2 dashboard:"
pm2 status dashboard
echo ""

# 2. Verificar puerto
echo "2. Verificando puerto 3010:"
netstat -tlnp | grep 3010 || echo "⚠️  Puerto 3010 no está escuchando"
echo ""

# 3. Verificar configuración de Traefik
echo "3. Verificando configuración de Traefik:"
if grep -q "dashboard.checkin24hs.com" /etc/easypanel/traefik/config/main.yaml; then
    echo "✅ Configuración encontrada:"
    grep -A 5 "dashboard.checkin24hs.com" /etc/easypanel/traefik/config/main.yaml | head -10
else
    echo "⚠️  No se encontró configuración para dashboard.checkin24hs.com"
fi
echo ""

# 4. Verificar logs de PM2
echo "4. Últimas líneas de logs del dashboard:"
pm2 logs dashboard --lines 10 --nostream
echo ""

echo "=========================================="
echo "🔧 Aplicando correcciones..."
echo "=========================================="

# Reiniciar dashboard
echo "Reiniciando dashboard..."
pm2 restart dashboard
sleep 3

# Verificar que esté corriendo
if pm2 list | grep -q "dashboard.*online"; then
    echo "✅ Dashboard está corriendo"
else
    echo "❌ Dashboard no está corriendo, iniciando..."
    pm2 start dashboard
    sleep 2
fi

# Verificar puerto
if netstat -tlnp | grep -q ":3010"; then
    echo "✅ Puerto 3010 está escuchando"
else
    echo "⚠️  Puerto 3010 no está escuchando"
fi

# Corregir Traefik si es necesario
TRAEFIK_CONFIG="/etc/easypanel/traefik/config/main.yaml"
if [ -f "$TRAEFIK_CONFIG" ]; then
    # Verificar si apunta al puerto correcto
    if grep -q "http://72.61.58.240:3010" "$TRAEFIK_CONFIG"; then
        echo "✅ Traefik está configurado correctamente"
    else
        echo "🔧 Corrigiendo configuración de Traefik..."
        # Crear backup
        cp "$TRAEFIK_CONFIG" "${TRAEFIK_CONFIG}.backup_$(date +%Y%m%d_%H%M%S)"
        
        # Corregir la URL
        sed -i 's|http://checkin24hs_dashboard:80/|http://72.61.58.240:3010|g' "$TRAEFIK_CONFIG"
        sed -i 's|http://localhost:3010|http://72.61.58.240:3010|g' "$TRAEFIK_CONFIG"
        
        echo "✅ Traefik corregido, reiniciando..."
        docker service update --force traefik
        sleep 5
        echo "✅ Traefik reiniciado"
    fi
else
    echo "⚠️  No se encontró el archivo de configuración de Traefik"
fi

echo ""
echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
echo ""
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com"
echo ""

