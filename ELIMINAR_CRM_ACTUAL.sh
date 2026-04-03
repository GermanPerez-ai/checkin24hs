#!/bin/bash

# Script para eliminar completamente el servicio CRM actual

echo "=== Eliminando servicio CRM actual ==="

SERVICE_NAME="checkin24hs_crm"

# Verificar si el servicio existe
if docker service ls | grep -q "$SERVICE_NAME"; then
    echo "Servicio encontrado: $SERVICE_NAME"
    
    # Ver estado actual
    echo ""
    echo "Estado actual:"
    docker service ps $SERVICE_NAME --no-trunc | head -5
    
    # Confirmar eliminación
    echo ""
    echo "¿Estás seguro de que quieres eliminar el servicio $SERVICE_NAME? (s/n)"
    read -r CONFIRM
    
    if [ "$CONFIRM" = "s" ] || [ "$CONFIRM" = "S" ] || [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        echo "Eliminando servicio..."
        docker service rm $SERVICE_NAME
        
        echo "Esperando 10 segundos..."
        sleep 10
        
        # Verificar que se eliminó
        if docker service ls | grep -q "$SERVICE_NAME"; then
            echo "ADVERTENCIA: El servicio aún existe"
        else
            echo "✅ Servicio eliminado correctamente"
        fi
        
        # Limpiar contenedores huérfanos
        echo ""
        echo "Limpiando contenedores huérfanos..."
        docker container prune -f
        
    else
        echo "Operación cancelada"
    fi
else
    echo "El servicio $SERVICE_NAME no existe"
fi

echo ""
echo "=== Proceso completado ==="
echo "Ahora puedes crear el servicio desde cero en EasyPanel"

