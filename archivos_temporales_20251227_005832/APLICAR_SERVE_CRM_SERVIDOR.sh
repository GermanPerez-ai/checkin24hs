#!/bin/bash

# Script para aplicar serve-crm.js al servidor del CRM
# Uso: ./APLICAR_SERVE_CRM_SERVIDOR.sh

set -e

echo "=== Aplicando serve-crm.js al servidor CRM ==="

# 1. Verificar que el archivo existe localmente
if [ ! -f "serve-crm.js" ]; then
    echo "ERROR: serve-crm.js no existe en el directorio actual"
    exit 1
fi

# 2. Verificar que crm.html existe
if [ ! -f "deploy/crm.html" ]; then
    echo "ERROR: deploy/crm.html no existe"
    exit 1
fi

# 3. Obtener contenedor del CRM
echo "Buscando contenedor del CRM..."
CONTAINER_ID=$(docker ps | grep checkin24hs_crm | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontró contenedor del CRM corriendo"
    echo "Verificando servicios..."
    docker service ls | grep crm
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"

# 4. Copiar serve-crm.js al contenedor
echo "Copiando serve-crm.js al contenedor..."
docker cp serve-crm.js $CONTAINER_ID:/app/serve-crm.js

# 5. Verificar que se copió
echo "Verificando que se copió correctamente..."
docker exec $CONTAINER_ID ls -lh /app/serve-crm.js

# 6. Verificar que crm.html existe en el contenedor
echo "Verificando crm.html..."
docker exec $CONTAINER_ID ls -lh /app/crm.html || echo "ADVERTENCIA: crm.html no encontrado en /app"

# 7. Reiniciar el servicio para aplicar cambios
echo "Reiniciando servicio CRM..."
docker service update --force checkin24hs_crm

# 8. Esperar a que el servicio se reinicie
echo "Esperando 30 segundos para que el servicio se reinicie..."
sleep 30

# 9. Verificar nuevo contenedor
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_crm | awk '{print $1}' | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    
    # Copiar archivo al nuevo contenedor también
    echo "Copiando serve-crm.js al nuevo contenedor..."
    docker cp serve-crm.js $NEW_CONTAINER_ID:/app/serve-crm.js
    
    # Verificar proceso
    echo "Verificando proceso..."
    docker exec $NEW_CONTAINER_ID ps aux | grep node
    
    # Verificar que el servidor responde
    echo "Verificando que el servidor responde..."
    docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3005 2>&1 | head -5 || echo "El servidor aún no responde, espera unos segundos más"
else
    echo "ADVERTENCIA: No se encontró nuevo contenedor después del reinicio"
fi

echo ""
echo "=== Proceso completado ==="
echo "Verifica los logs con: docker service logs checkin24hs_crm --tail 50"

