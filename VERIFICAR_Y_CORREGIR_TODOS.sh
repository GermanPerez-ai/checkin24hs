#!/bin/bash
cd /root/checkin24hs

echo "Verificando archivo en servidor..."
LINE_5150_SERVER=$(sed -n '5150p' deploy/dashboard.html)
echo "Línea 5150 en servidor: $LINE_5150_SERVER"
echo ""

echo "Verificando y corrigiendo TODOS los contenedores..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "=== Contenedor: $container ==="
    
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    SHOW_SECTION_LINE=$(docker exec $container grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
    
    NEEDS_FIX=false
    
    if echo "$LINE_5150" | grep -q "/*"; then
        echo "Línea 5150 tiene comentario - necesita corrección"
        NEEDS_FIX=true
    elif [ -z "$SHOW_SECTION_LINE" ] || [ "$SHOW_SECTION_LINE" -gt 2000 ]; then
        echo "Funciones globales en línea $SHOW_SECTION_LINE - necesita corrección"
        NEEDS_FIX=true
    fi
    
    if [ "$NEEDS_FIX" = true ]; then
        echo "Copiando archivo correcto..."
        docker cp deploy/dashboard.html $container:/app/dashboard.html
        sleep 1
        
        LINE_5150_NEW=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        echo "Línea 5150 después: $LINE_5150_NEW"
        
        docker restart $container
        echo "Contenedor reiniciado"
    else
        echo "Contenedor correcto - Línea 5150: $LINE_5150, Funciones en línea: $SHOW_SECTION_LINE"
    fi
    
    echo ""
done

echo "Proceso completado!"
