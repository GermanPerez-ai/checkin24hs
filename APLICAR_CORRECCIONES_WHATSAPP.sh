#!/bin/bash
# Script para aplicar correcciones de WhatsApp en contenedores Docker

cd /root/checkin24hs

echo "🔍 Buscando contenedores..."

# Buscar contenedor CRM
CRM_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i crm | head -1)
if [ ! -z "$CRM_CONTAINER" ]; then
    echo "📦 Contenedor CRM encontrado: $CRM_CONTAINER"
    echo "   Copiando crm.html..."
    docker cp deploy/crm.html $CRM_CONTAINER:/usr/share/nginx/html/crm.html 2>/dev/null || \
    docker cp deploy/crm.html $CRM_CONTAINER:/app/crm.html 2>/dev/null || \
    echo "   ⚠️ No se pudo copiar crm.html"
    
    echo "   Copiando crm.js..."
    docker cp deploy/crm.js $CRM_CONTAINER:/usr/share/nginx/html/crm.js 2>/dev/null || \
    docker cp deploy/crm.js $CRM_CONTAINER:/app/crm.js 2>/dev/null || \
    echo "   ⚠️ No se pudo copiar crm.js"
    
    echo "   Reiniciando contenedor CRM..."
    docker restart $CRM_CONTAINER
    echo "   ✅ Contenedor CRM reiniciado"
else
    echo "   ⚠️ No se encontró contenedor CRM"
fi

# Buscar contenedor Dashboard
DASHBOARD_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i dashboard | head -1)
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "📦 Contenedor Dashboard encontrado: $DASHBOARD_CONTAINER"
    echo "   Copiando dashboard.html..."
    docker cp deploy/dashboard.html $DASHBOARD_CONTAINER:/usr/share/nginx/html/dashboard.html 2>/dev/null || \
    docker cp deploy/dashboard.html $DASHBOARD_CONTAINER:/app/dashboard.html 2>/dev/null || \
    echo "   ⚠️ No se pudo copiar dashboard.html"
    
    echo "   Reiniciando contenedor Dashboard..."
    docker restart $DASHBOARD_CONTAINER
    echo "   ✅ Contenedor Dashboard reiniciado"
else
    echo "   ⚠️ No se encontró contenedor Dashboard"
fi

# Si no hay contenedores, verificar si hay servicios PM2
if [ -z "$CRM_CONTAINER" ] && [ -z "$DASHBOARD_CONTAINER" ]; then
    echo ""
    echo "🔍 Verificando servicios PM2..."
    pm2 list | grep -E '(crm|dashboard)' || echo "   No hay servicios PM2 relacionados"
fi

echo ""
echo "✅ Proceso completado!"

