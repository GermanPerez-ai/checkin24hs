#!/bin/bash
# Script para corregir el contenedor nuevo que tiene error

cd /root/checkin24hs

echo "=== CORRIGIENDO CONTENEDOR NUEVO ==="
echo ""

# Contenedor problemático
PROBLEM_CONTAINER="checkin24hs_dashboard.1.8v793ovw45rwpxlzdi7d7qcho"

# Verificar si existe
if docker ps --filter "name=$PROBLEM_CONTAINER" --format "{{.Names}}" | grep -q "$PROBLEM_CONTAINER"; then
    echo "Contenedor encontrado: $PROBLEM_CONTAINER"
    echo ""
    
    # Detener contenedor
    echo "Deteniendo contenedor..."
    docker stop $PROBLEM_CONTAINER
    
    sleep 2
    
    # Copiar archivo
    echo "Copiando archivo correcto..."
    docker cp deploy/dashboard.html $PROBLEM_CONTAINER:/app/dashboard.html
    
    # Verificar
    echo "Verificando línea 5150..."
    line_5150=$(docker exec $PROBLEM_CONTAINER sed -n '5150p' /app/dashboard.html 2>/dev/null)
    echo "Línea 5150: $line_5150"
    
    if echo "$line_5150" | grep -q "editHotelName"; then
        echo "OK: Archivo correcto"
        
        # Reiniciar
        echo "Reiniciando contenedor..."
        docker start $PROBLEM_CONTAINER
        
        sleep 3
        
        # Verificar final
        echo ""
        echo "Verificación final:"
        final_line=$(docker exec $PROBLEM_CONTAINER sed -n '5150p' /app/dashboard.html 2>/dev/null)
        if echo "$final_line" | grep -q "editHotelName"; then
            echo "✅ Contenedor corregido correctamente"
        else
            echo "❌ Error al verificar"
        fi
    else
        echo "ERROR: Archivo no se corrigió correctamente"
    fi
else
    echo "Contenedor no encontrado o ya fue recreado"
    echo ""
    echo "Verificando todos los contenedores activos:"
    docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read container; do
        line_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        if echo "$line_5150" | grep -q "editHotelName"; then
            echo "✅ $container: OK"
        else
            echo "❌ $container: ERROR - Corrigiendo..."
            docker stop $container > /dev/null 2>&1
            sleep 1
            docker cp deploy/dashboard.html $container:/app/dashboard.html
            docker start $container > /dev/null 2>&1
            echo "   Corregido"
        fi
    done
fi

echo ""
echo "=== PROCESO COMPLETADO ==="








