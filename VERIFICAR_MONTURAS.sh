#!/bin/bash
# Verificar si hay bind mounts o volúmenes montados

echo "🔍 Verificando configuración del servicio..."
echo ""

# Encontrar contenedor
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# Ver montajes
echo "📋 Montajes del contenedor:"
docker inspect ${CONTAINER_ID} --format='{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}}){{println}}{{end}}'

echo ""
echo "📋 Verificar si /app está montado:"
docker inspect ${CONTAINER_ID} --format='{{range .Mounts}}{{if eq .Destination "/app"}}⚠️  /app está montado desde: {{.Source}}{{end}}{{end}}'

echo ""
echo "📋 Archivo en host:"
ls -lh /etc/easypanel/projects/checkin24hs/dashboard/code/dashboard.html 2>/dev/null | head -1

echo ""
echo "📋 Archivo en contenedor:"
docker exec ${CONTAINER_ID} ls -lh /app/dashboard.html 2>/dev/null || echo "No encontrado en /app"
