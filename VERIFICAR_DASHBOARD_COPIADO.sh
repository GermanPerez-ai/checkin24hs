#!/bin/bash
# Script para verificar que dashboard.html se copió correctamente

cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO DASHBOARD.HTML ==="
echo ""

# Verificar que el archivo existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ ERROR: No se encuentra deploy/dashboard.html"
    exit 1
fi

echo "✅ Archivo encontrado"
echo ""

# Verificar tamaño del archivo
file_size=$(stat -f%z deploy/dashboard.html 2>/dev/null || stat -c%s deploy/dashboard.html 2>/dev/null)
echo "📊 Tamaño del archivo: $file_size bytes"
echo ""

# Verificar que contiene las funciones globales
echo "🔍 Verificando funciones globales..."
if grep -q "window.showSection = function" deploy/dashboard.html; then
    echo "✅ window.showSection encontrada"
else
    echo "❌ window.showSection NO encontrada"
fi

if grep -q "window.searchUsers = function" deploy/dashboard.html; then
    echo "✅ window.searchUsers encontrada"
else
    echo "❌ window.searchUsers NO encontrada"
fi

if grep -q "buildServerURL" deploy/dashboard.html; then
    echo "✅ buildServerURL encontrada"
else
    echo "❌ buildServerURL NO encontrada"
fi

echo ""
echo "=== VERIFICANDO CONTENEDORES ==="
echo ""

# Verificar contenedores del dashboard
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        echo "📦 Verificando $container..."
        
        # Verificar que el archivo existe en el contenedor
        if docker exec $container test -f /app/dashboard.html; then
            container_size=$(docker exec $container stat -f%z /app/dashboard.html 2>/dev/null || docker exec $container stat -c%s /app/dashboard.html 2>/dev/null)
            echo "   ✅ Archivo existe en contenedor (tamaño: $container_size bytes)"
            
            # Verificar funciones globales en el contenedor
            if docker exec $container grep -q "window.showSection = function" /app/dashboard.html; then
                echo "   ✅ window.showSection encontrada en contenedor"
            else
                echo "   ❌ window.showSection NO encontrada en contenedor"
            fi
        else
            echo "   ❌ Archivo NO existe en contenedor"
        fi
        echo ""
    fi
done

echo "✅✅✅ VERIFICACIÓN COMPLETADA ✅✅✅"








