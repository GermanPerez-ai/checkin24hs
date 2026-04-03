#!/bin/bash

# Script para aplicar serve-crm.js manualmente al servidor
# Uso: ./APLICAR_CRM_MANUAL_SERVIDOR.sh

set -e

echo "=== Aplicando serve-crm.js al servidor CRM ==="

# 1. Verificar que el archivo existe en el servidor
if [ ! -f "/root/checkin24hs/serve-crm.js" ]; then
    echo "ERROR: serve-crm.js no existe en /root/checkin24hs/"
    echo "Primero sube el archivo con: scp serve-crm.js root@TU_SERVIDOR:/root/checkin24hs/"
    exit 1
fi

# 2. Verificar servicios CRM disponibles
echo "Buscando servicios CRM..."
docker service ls | grep -i crm || echo "No se encontraron servicios con 'crm' en el nombre"

# 3. Intentar diferentes nombres posibles
SERVICE_NAME=""
for name in "checkin24hs_crm" "crm" "checkin24hs-crm"; do
    if docker service ls | grep -q "$name"; then
        SERVICE_NAME="$name"
        echo "Servicio encontrado: $SERVICE_NAME"
        break
    fi
done

if [ -z "$SERVICE_NAME" ]; then
    echo ""
    echo "ERROR: No se encontró el servicio CRM"
    echo "Servicios disponibles:"
    docker service ls
    echo ""
    echo "Por favor, proporciona el nombre exacto del servicio:"
    read -p "Nombre del servicio: " SERVICE_NAME
fi

# 4. Obtener contenedor
echo "Buscando contenedor del servicio $SERVICE_NAME..."
CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "No se encontró contenedor corriendo. Intentando obtener de docker service ps..."
    CONTAINER_ID=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}" | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "ERROR: No se encontró contenedor del servicio $SERVICE_NAME"
        echo "Estado del servicio:"
        docker service ps $SERVICE_NAME
        exit 1
    fi
    
    # Obtener el nombre completo del contenedor
    CONTAINER_NAME=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.Name}}" | head -1)
    CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se pudo obtener el ID del contenedor"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"

# 5. Copiar archivo al contenedor
echo "Copiando serve-crm.js al contenedor..."
docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js

# 6. Verificar que se copió
echo "Verificando que se copió correctamente..."
docker exec $CONTAINER_ID ls -lh /app/serve-crm.js

# 7. Verificar que crm.html existe
echo "Verificando crm.html..."
docker exec $CONTAINER_ID ls -lh /app/crm.html 2>/dev/null || echo "ADVERTENCIA: crm.html no encontrado en /app"

# 8. Reiniciar servicio
echo "Reiniciando servicio $SERVICE_NAME..."
docker service update --force $SERVICE_NAME

# 9. Esperar a que se reinicie
echo "Esperando 30 segundos para que el servicio se reinicie..."
sleep 30

# 10. Verificar nuevo contenedor
echo "Buscando nuevo contenedor..."
NEW_CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    
    # Copiar archivo al nuevo contenedor también
    echo "Copiando serve-crm.js al nuevo contenedor..."
    docker cp /root/checkin24hs/serve-crm.js $NEW_CONTAINER_ID:/app/serve-crm.js
    
    # Verificar proceso
    echo "Verificando proceso..."
    docker exec $NEW_CONTAINER_ID ps aux | grep node || echo "No se encontró proceso node"
    
    # Verificar logs
    echo "Últimos logs del servicio:"
    docker service logs $SERVICE_NAME --tail 20
else
    echo "ADVERTENCIA: No se encontró nuevo contenedor después del reinicio"
    echo "Verificando estado del servicio:"
    docker service ps $SERVICE_NAME
fi

echo ""
echo "=== Proceso completado ==="
echo "Verifica los logs con: docker service logs $SERVICE_NAME --tail 50"

