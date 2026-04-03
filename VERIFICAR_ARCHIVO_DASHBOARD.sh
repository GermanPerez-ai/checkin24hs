#!/bin/bash
# Script para verificar el archivo dashboard.html en el servidor y contenedores

cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO DASHBOARD.HTML ==="
echo ""

# Verificar archivo en el servidor
echo "📁 Archivo en servidor:"
if [ -f "deploy/dashboard.html" ]; then
    server_size=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
    echo "   Tamaño: $server_size bytes"
    
    # Verificar línea 5150
    echo ""
    echo "📄 Línea 5150 en servidor:"
    sed -n '5150p' deploy/dashboard.html
    echo ""
    
    # Verificar contexto alrededor de línea 5150
    echo "📄 Contexto líneas 5145-5155:"
    sed -n '5145,5155p' deploy/dashboard.html
    echo ""
else
    echo "   ❌ Archivo NO encontrado"
fi

echo ""
echo "=== VERIFICANDO CONTENEDORES ==="
echo ""

# Verificar contenedores
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        echo "📦 Contenedor: $container"
        
        # Verificar tamaño
        if docker exec $container test -f /app/dashboard.html 2>/dev/null; then
            container_size=$(docker exec $container stat -c%s /app/dashboard.html 2>/dev/null || docker exec $container stat -f%z /app/dashboard.html 2>/dev/null)
            echo "   Tamaño: $container_size bytes"
            
            # Verificar línea 5150
            echo "   Línea 5150:"
            docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null || echo "   Error leyendo línea"
            
            # Comparar tamaños
            if [ "$server_size" != "$container_size" ]; then
                echo "   ⚠️ ADVERTENCIA: Tamaño diferente! Servidor: $server_size, Contenedor: $container_size"
            else
                echo "   ✅ Tamaño coincide"
            fi
        else
            echo "   ❌ Archivo NO existe en contenedor"
        fi
        echo ""
    fi
done

echo "✅✅✅ VERIFICACIÓN COMPLETADA ✅✅✅"








