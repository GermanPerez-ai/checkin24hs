#!/bin/bash

# Script completo para reparar el servicio CRM

set -e

SERVICE_NAME="checkin24hs_crm"

echo "=== Reparando servicio CRM ==="

# 1. Verificar que el archivo existe
if [ ! -f "/root/checkin24hs/serve-crm.js" ]; then
    echo "ERROR: serve-crm.js no existe"
    exit 1
fi

# 2. Ver estado actual
echo "Estado actual del servicio:"
docker service ps $SERVICE_NAME --no-trunc | head -5

# 3. Si el servicio está pausado, reanudarlo
echo ""
echo "Reanudando servicio si está pausado..."
docker service update --update-parallelism 1 --update-delay 10s $SERVICE_NAME 2>&1 | head -5

# 4. Esperar un momento
sleep 10

# 5. Copiar archivo a TODOS los contenedores (corriendo y detenidos)
echo ""
echo "Copiando archivo a todos los contenedores..."
ALL_CONTAINERS=$(docker ps -a --filter "name=$SERVICE_NAME" --format "{{.ID}} {{.Names}} {{.Status}}")
while IFS= read -r line; do
    CONTAINER_ID=$(echo "$line" | awk '{print $1}')
    CONTAINER_NAME=$(echo "$line" | awk '{print $2}')
    STATUS=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')
    
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "Procesando: $CONTAINER_NAME ($CONTAINER_ID) - $STATUS"
        
        # Intentar copiar
        if docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1; then
            echo "  -> Archivo copiado correctamente"
            
            # Si el contenedor está corriendo, verificar
            if echo "$STATUS" | grep -q "Up"; then
                docker exec $CONTAINER_ID ls -lh /app/serve-crm.js 2>&1 | head -1 || echo "  -> ADVERTENCIA: No se pudo verificar"
            fi
        else
            echo "  -> ADVERTENCIA: No se pudo copiar (contenedor puede estar detenido)"
        fi
    fi
done <<< "$ALL_CONTAINERS"

# 6. Reiniciar servicio
echo ""
echo "Reiniciando servicio..."
docker service update --force $SERVICE_NAME

# 7. Esperar a que se reinicie
echo "Esperando 45 segundos para que se reinicien los contenedores..."
sleep 45

# 8. Copiar a contenedores nuevos
echo ""
echo "Copiando archivo a contenedores nuevos..."
NEW_CONTAINERS=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}} {{.Names}}")
if [ ! -z "$NEW_CONTAINERS" ]; then
    while IFS= read -r line; do
        CONTAINER_ID=$(echo "$line" | awk '{print $1}')
        CONTAINER_NAME=$(echo "$line" | awk '{print $2}')
        
        if [ ! -z "$CONTAINER_ID" ]; then
            echo "Copiando a nuevo contenedor: $CONTAINER_NAME ($CONTAINER_ID)"
            docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1
            
            echo "Verificando archivo:"
            docker exec $CONTAINER_ID ls -lh /app/serve-crm.js 2>&1 | head -1 || echo "  ERROR"
            
            echo "Verificando proceso:"
            docker exec $CONTAINER_ID ps aux | grep node | head -3 || echo "  No hay proceso node"
        fi
    done <<< "$NEW_CONTAINERS"
else
    echo "ADVERTENCIA: No se encontraron contenedores corriendo"
fi

# 9. Ver logs finales
echo ""
echo "=== Logs del servicio ==="
docker service logs $SERVICE_NAME --tail 30

# 10. Ver estado final
echo ""
echo "=== Estado final del servicio ==="
docker service ps $SERVICE_NAME --no-trunc | head -5

echo ""
echo "=== Proceso completado ==="
echo "Si aún hay errores, verifica:"
echo "  1. Que el comando en EasyPanel sea: node serve-crm.js"
echo "  2. Que el archivo crm.html exista en /app del contenedor"
echo "  3. Los logs completos: docker service logs $SERVICE_NAME --tail 100"

