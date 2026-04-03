#!/bin/bash

cd /root/checkin24hs

echo "=== Verificando contenedores activos ==="
docker ps | grep dashboard

echo ""
echo "=== Verificando servicio Docker Swarm ==="
docker service ls | grep dashboard

echo ""
echo "=== Verificando puerto 3000 en contenedores ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor: $CONTAINER"
docker exec "$CONTAINER" netstat -tlnp 2>/dev/null | grep 3000 || docker exec "$CONTAINER" ss -tlnp 2>/dev/null | grep 3000 || echo "No se pudo verificar el puerto"

echo ""
echo "=== Verificando logs del servicio (últimas 20 líneas) ==="
docker service logs checkin24hs_dashboard --tail 20 2>&1 | tail -20

echo ""
echo "=== Verificando configuración de Traefik ==="
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Labels}}{{.}}{{println}}{{end}}' | grep -i traefik | head -10

echo ""
echo "=== Probando acceso interno ==="
docker exec "$CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "curl no disponible"


