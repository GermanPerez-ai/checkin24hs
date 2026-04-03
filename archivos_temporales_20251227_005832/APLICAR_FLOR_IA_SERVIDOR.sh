#!/bin/bash
# Script para aplicar corrección "Flor IA" en el servidor

echo "=== Aplicar Correccion: Flor IA en Menu ==="
echo ""

# 1. Dashboard
echo "📋 Aplicando corrección en Dashboard..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    if [ -f "/root/checkin24hs/deploy/dashboard.html" ]; then
        docker cp /root/checkin24hs/deploy/dashboard.html $DASHBOARD_CONTAINER:/app/dashboard.html
        echo "✅ Dashboard actualizado"
        
        # Verificar
        docker exec $DASHBOARD_CONTAINER grep -n "Flor IA" /app/dashboard.html | grep "menu-item" | head -1
    else
        echo "⚠️  Archivo /root/checkin24hs/deploy/dashboard.html no encontrado"
    fi
else
    echo "⚠️  Contenedor del Dashboard no encontrado"
fi

echo ""

# 2. CRM
echo "📋 Aplicando corrección en CRM..."
CRM_CONTAINER=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)

if [ ! -z "$CRM_CONTAINER" ]; then
    if [ -f "/root/checkin24hs/deploy/crm.html" ]; then
        docker cp /root/checkin24hs/deploy/crm.html $CRM_CONTAINER:/app/crm.html
        echo "✅ CRM actualizado"
        
        # Verificar
        docker exec $CRM_CONTAINER grep -n "Flor IA" /app/crm.html | grep "menu-item" | head -1
    else
        echo "⚠️  Archivo /root/checkin24hs/deploy/crm.html no encontrado"
    fi
else
    echo "⚠️  Contenedor del CRM no encontrado"
fi

echo ""
echo "✅ Corrección aplicada"
echo "💡 Recarga con Ctrl+F5 para ver los cambios"






