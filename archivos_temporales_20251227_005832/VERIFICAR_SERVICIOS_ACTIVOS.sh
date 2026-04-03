#!/bin/bash
# Verificar todos los servicios activos para entender la estructura

echo "=== Servicios Docker Activos ==="
docker service ls
echo ""

echo "=== Contenedores Activos ==="
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
echo ""

echo "=== Buscar cualquier referencia a WhatsApp ==="
docker service ls --format "{{.Name}}" | grep -i whatsapp || echo "No hay servicios con 'whatsapp' en el nombre"
docker ps --format "{{.Names}}" | grep -i whatsapp || echo "No hay contenedores con 'whatsapp' en el nombre"
echo ""

echo "=== Buscar puertos 3001-3004 ==="
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004" || echo "No hay contenedores en puertos 3001-3004"
echo ""

echo "=== Verificar si hay servicios en EasyPanel ==="
docker ps --format "{{.Names}}" | grep -i easypanel
echo ""

echo "=== Verificar red easypanel ==="
docker network inspect easypanel --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | head -20
echo ""






