#!/bin/bash
# Script para verificar qué contenedor está sirviendo realmente

echo "🔍 Verificando contenedores activos..."
echo ""

# Ver todos los contenedores de dashboard
echo "📋 Contenedores de dashboard:"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "checkin24hs_dashboard"

echo ""
echo "🔍 Verificando archivos en cada contenedor..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "📦 Contenedor: $container"
    
    # Verificar línea 5150
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    echo "   Línea 5150: $LINE_5150"
    
    # Verificar funciones globales
    SHOW_SECTION_LINE=$(docker exec $container grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
    echo "   Funciones globales en línea: $SHOW_SECTION_LINE"
    
    # Ver tamaño del archivo
    SIZE=$(docker exec $container ls -lh /app/dashboard.html 2>/dev/null | awk '{print $5}')
    echo "   Tamaño: $SIZE"
    
    echo ""
done

echo "💡 Si algún contenedor NO tiene las correcciones, cópialo manualmente:"
echo "   docker cp /root/checkin24hs/deploy/dashboard.html <contenedor>:/app/dashboard.html"
echo "   docker restart <contenedor>"




