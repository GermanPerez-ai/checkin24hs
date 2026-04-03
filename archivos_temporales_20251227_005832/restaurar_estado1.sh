#!/bin/bash
# Script para restaurar desde estado1
# Ejecutar desde cualquier ubicación

echo "=========================================="
echo "Restaurando desde estado1"
echo "=========================================="
echo ""

BACKUP_DIR="/root/checkin24hs/backups/estado1"

if [ ! -f "$BACKUP_DIR/dashboard.html" ]; then
    echo "ERROR: No se encontro el backup de estado1"
    echo "       Asegurate de haber creado el punto de restauracion primero"
    exit 1
fi

# 1. Restaurar dashboard.html
echo "1. Restaurando dashboard.html..."
cp "$BACKUP_DIR/dashboard.html" /root/checkin24hs/dashboard.html
echo "   OK: dashboard.html restaurado"
echo ""

# 2. Aplicar al contenedor
echo "2. Aplicando al contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    docker cp /root/checkin24hs/dashboard.html ${CONTAINER_ID}:/app/dashboard.html
    echo "   OK: Archivo copiado al contenedor $CONTAINER_ID"
    
    # Reiniciar servicio
    echo "   Reiniciando servicio..."
    docker service update --force checkin24hs_dashboard
    
    echo ""
    echo "   Esperando 30 segundos..."
    sleep 30
    
    # Copiar al nuevo contenedor
    NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
    if [ ! -z "$NEW_CONTAINER_ID" ]; then
        docker cp /root/checkin24hs/dashboard.html ${NEW_CONTAINER_ID}:/app/dashboard.html
        echo "   OK: Archivo copiado al nuevo contenedor $NEW_CONTAINER_ID"
    fi
else
    echo "   ERROR: No hay contenedor corriendo"
fi

echo ""
echo "=========================================="
echo "Restauracion completada"
echo "=========================================="
echo ""
echo "Recarga el dashboard con Ctrl+F5"


