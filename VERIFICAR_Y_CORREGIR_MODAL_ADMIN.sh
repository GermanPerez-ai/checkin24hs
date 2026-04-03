#!/bin/bash

# Script para verificar y corregir el modal de administradores

echo "=== VERIFICAR MODAL DE ADMINISTRADORES ==="
echo ""

cd /root/checkin24hs

# Verificar que existe el archivo
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encontró deploy/dashboard.html"
    exit 1
fi

echo "✅ Archivo encontrado"
echo ""

# Verificar que el modal existe
if grep -q "adminModal" deploy/dashboard.html; then
    echo "✅ Modal adminModal encontrado en el archivo"
else
    echo "❌ ERROR: Modal adminModal NO encontrado"
    exit 1
fi

# Verificar función showNewAdminModal
if grep -q "function showNewAdminModal" deploy/dashboard.html; then
    echo "✅ Función showNewAdminModal encontrada"
else
    echo "❌ ERROR: Función showNewAdminModal NO encontrada"
    exit 1
fi

# Contar líneas del archivo
LINES=$(wc -l < deploy/dashboard.html)
echo "📊 Total de líneas: $LINES"
echo ""

# Verificar que tiene al menos 20000 líneas (el archivo completo debería tener ~23313)
if [ $LINES -lt 20000 ]; then
    echo "⚠️ ADVERTENCIA: El archivo parece estar incompleto (menos de 20000 líneas)"
    echo "   El archivo completo debería tener aproximadamente 23313 líneas"
fi

echo ""
echo "=== APLICAR A CONTENEDORES ==="
echo ""

# 1. Detener contenedores
echo "🛑 Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
echo "✅ Contenedores detenidos"
echo ""

# 2. Copiar archivo
echo "📋 Copiando archivo a contenedores..."
for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "  Copiando a: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null || \
    docker cp deploy/dashboard.html $container:/usr/share/nginx/html/dashboard.html 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "    ✅ Copiado exitosamente"
    else
        echo "    ❌ Error al copiar"
    fi
done
echo ""

# 3. Reiniciar contenedores
echo "🚀 Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
echo "✅ Contenedores reiniciados"
echo ""

# 4. Verificar estado
echo "📊 Estado de contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep "checkin24hs_dashboard"
echo ""

echo "✅ Proceso completado!"
echo ""
echo "Verifica el dashboard en: https://dashboard.checkin24hs.com/"
echo "Presiona Ctrl+F5 para refrescar sin caché"










