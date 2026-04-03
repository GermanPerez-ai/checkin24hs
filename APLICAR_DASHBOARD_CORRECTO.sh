#!/bin/bash

# Script para aplicar dashboard.html correctamente a todos los contenedores
# Solución: Detener contenedores, copiar archivo, reiniciar

echo "=== APLICAR DASHBOARD CORRECTO ==="
echo ""

cd /root/checkin24hs

# Verificar que existe el archivo
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encontró deploy/dashboard.html"
    exit 1
fi

echo "✅ Archivo encontrado: deploy/dashboard.html"
echo ""

# 1. Detener TODOS los contenedores de dashboard
echo "🛑 Paso 1: Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
echo "✅ Contenedores detenidos"
echo ""

# 2. Copiar archivo a cada contenedor
echo "📋 Paso 2: Copiando archivo a contenedores..."
for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "  Copiando a: $container"
    # Intentar ambas rutas posibles
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null || \
    docker cp deploy/dashboard.html $container:/usr/share/nginx/html/dashboard.html 2>/dev/null || \
    echo "  ⚠️ No se pudo copiar a $container"
done
echo "✅ Archivo copiado"
echo ""

# 3. Reiniciar contenedores
echo "🚀 Paso 3: Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
echo "✅ Contenedores reiniciados"
echo ""

# 4. Verificar estado
echo "📊 Estado de contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep "checkin24hs_dashboard"
echo ""

echo "✅ Proceso completado!"
echo ""
echo "Ahora verifica el dashboard en: https://dashboard.checkin24hs.com/"
echo "Presiona Ctrl+F5 para refrescar sin caché"










