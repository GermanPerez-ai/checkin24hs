#!/bin/bash
# Script robusto para aplicar dashboard.html a todos los contenedores

cd /root/checkin24hs

echo "=== APLICANDO DASHBOARD.HTML A TODOS LOS CONTENEDORES ==="
echo ""

# Verificar archivo en servidor
if [ ! -f "deploy/dashboard.html" ]; then
    echo "ERROR: No se encuentra deploy/dashboard.html"
    exit 1
fi

server_size=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "Archivo en servidor: $server_size bytes ($(echo "scale=2; $server_size/1024/1024" | bc) MB)"
echo ""

# Obtener todos los contenedores activos
containers=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}")

if [ -z "$containers" ]; then
    echo "No se encontraron contenedores del dashboard"
    exit 1
fi

echo "Contenedores encontrados:"
echo "$containers"
echo ""

# Copiar a cada contenedor
echo "$containers" | while read container; do
    if [ ! -z "$container" ]; then
        echo "=== Procesando: $container ==="
        
        # Copiar archivo
        docker cp deploy/dashboard.html $container:/app/dashboard.html
        
        # Verificar que se copió correctamente
        container_size=$(docker exec $container stat -c%s /app/dashboard.html 2>/dev/null || docker exec $container stat -f%z /app/dashboard.html 2>/dev/null)
        
        if [ "$server_size" = "$container_size" ]; then
            echo "  Tamaño correcto: $container_size bytes"
            
            # Verificar línea 5150
            line_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
            if echo "$line_5150" | grep -q "editHotelName"; then
                echo "  Línea 5150 correcta"
            else
                echo "  ADVERTENCIA: Línea 5150 puede tener problemas"
                echo "  Contenido: $line_5150"
            fi
            
            # Reiniciar contenedor
            docker restart $container > /dev/null 2>&1
            echo "  Reiniciado correctamente"
        else
            echo "  ERROR: Tamaño diferente! Servidor: $server_size, Contenedor: $container_size"
        fi
        echo ""
    fi
done

echo "=== PROCESO COMPLETADO ==="
echo ""
echo "Ahora limpia la cache del navegador:"
echo "1. Presiona Ctrl+Shift+Delete"
echo "2. Selecciona 'Cached images and files'"
echo "3. Click 'Clear data'"
echo "4. Recarga con Ctrl+Shift+R"








