#!/bin/bash
# Verificar qué contenedor Docker usa el puerto 80

echo "=== Contenedores Docker corriendo ==="
docker ps

echo ""
echo "=== Ver qué contenedor usa el puerto 80 ==="
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" | grep -E "80|ID"

echo ""
echo "=== Verificar si EasyPanel está corriendo ==="
docker ps | grep -i "easypanel\|traefik\|caddy"

echo ""
echo "=== Opciones ==="
echo "1. Si EasyPanel está manejando el proxy, configurar el dominio ahí"
echo "2. Si no, detener el contenedor que usa el puerto 80"
echo "3. O configurar Nginx en otro puerto (no recomendado)"

