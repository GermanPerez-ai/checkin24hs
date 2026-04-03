#!/bin/bash

# Script para aplicar serve-crm.js a TODOS los contenedores del servicio CRM

set -e

echo "=== Aplicando serve-crm.js a todos los contenedores CRM ==="

SERVICE_NAME="checkin24hs_crm"

# Verificar que el archivo existe
if [ ! -f "/root/checkin24hs/serve-crm.js" ]; then
    echo "ERROR: serve-crm.js no existe en /root/checkin24hs/"
    exit 1
fi

echo "Archivo encontrado: /root/checkin24hs/serve-crm.js"

# Obtener TODOS los contenedores relacionados con el servicio
echo ""
echo "Buscando todos los contenedores del servicio $SERVICE_NAME..."

# Obtener todos los nombres de contenedores del servicio
CONTAINER_NAMES=$(docker service ps $SERVICE_NAME --format "{{.Name}}" | sort -u)

if [ -z "$CONTAINER_NAMES" ]; then
    echo "ERROR: No se encontraron contenedores del servicio"
    exit 1
fi

echo "Contenedores encontrados:"
echo "$CONTAINER_NAMES"

# Copiar archivo a cada contenedor
echo ""
echo "Copiando serve-crm.js a todos los contenedores..."

for CONTAINER_NAME in $CONTAINER_NAMES; do
    # Obtener ID del contenedor (puede estar corriendo o detenido)
    CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "Copiando a contenedor: $CONTAINER_NAME ($CONTAINER_ID)"
        
        # Verificar si el contenedor está corriendo
        if docker ps --format "{{.ID}}" | grep -q "$CONTAINER_ID"; then
            echo "  -> Contenedor está corriendo"
            docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1
            echo "  -> Verificando archivo..."
            docker exec $CONTAINER_ID ls -lh /app/serve-crm.js 2>&1 | head -1 || echo "  -> ADVERTENCIA: No se pudo verificar"
        else
            echo "  -> Contenedor está detenido, copiando de todas formas..."
            docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1 || echo "  -> ADVERTENCIA: No se pudo copiar (contenedor detenido)"
        fi
    else
        echo "  -> No se encontró ID para $CONTAINER_NAME"
    fi
done

echo ""
echo "=== Reiniciando servicio ==="
docker service update --force $SERVICE_NAME

echo "Esperando 40 segundos para que se reinicien todos los contenedores..."
sleep 40

echo ""
echo "=== Verificando estado final ==="

# Obtener contenedores corriendo después del reinicio
RUNNING_CONTAINERS=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}} {{.Names}}")

if [ ! -z "$RUNNING_CONTAINERS" ]; then
    echo "Contenedores corriendo:"
    echo "$RUNNING_CONTAINERS"
    
    echo ""
    echo "Copiando archivo a contenedores nuevos..."
    while IFS= read -r line; do
        CONTAINER_ID=$(echo "$line" | awk '{print $1}')
        CONTAINER_NAME=$(echo "$line" | awk '{print $2}')
        
        if [ ! -z "$CONTAINER_ID" ]; then
            echo "Copiando a $CONTAINER_NAME ($CONTAINER_ID)..."
            docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1
            docker exec $CONTAINER_ID ls -lh /app/serve-crm.js 2>&1 | head -1 || echo "  -> ADVERTENCIA"
        fi
    done <<< "$RUNNING_CONTAINERS"
else
    echo "ADVERTENCIA: No se encontraron contenedores corriendo"
fi

echo ""
echo "=== Logs del servicio ==="
docker service logs $SERVICE_NAME --tail 30

echo ""
echo "=== Proceso completado ==="
echo "Verifica los logs con: docker service logs $SERVICE_NAME --tail 50"

