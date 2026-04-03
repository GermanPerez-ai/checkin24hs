#!/bin/bash
# Buscar contenedor del dashboard
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $NF}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor del dashboard"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"

# Buscar el archivo dashboard.html en el contenedor
DASHBOARD_PATH=$(docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    echo "ERROR: No se encontro dashboard.html en el contenedor"
    exit 1
fi

echo "Archivo encontrado en: $DASHBOARD_PATH"

# Copiar el archivo a /tmp para descargarlo
docker cp $CONTAINER_ID:$DASHBOARD_PATH /tmp/dashboard_servidor.html

if [ $? -eq 0 ]; then
    echo "OK: Archivo copiado a /tmp/dashboard_servidor.html"
    echo "RUTA_ARCHIVO=/tmp/dashboard_servidor.html"
else
    echo "ERROR: No se pudo copiar el archivo"
    exit 1
fi