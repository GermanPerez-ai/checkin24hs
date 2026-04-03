#!/bin/bash
# Script para verificar qué archivo está sirviendo realmente el contenedor

cd /root/checkin24hs

echo "=== VERIFICANDO ARCHIVO QUE SE ESTÁ SIRVIENDO ==="
echo ""

# Obtener un contenedor activo
container=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$container" ]; then
    echo "No se encontraron contenedores"
    exit 1
fi

echo "Contenedor: $container"
echo ""

# Verificar línea 5150 y contexto
echo "Línea 5150:"
docker exec $container sed -n '5150p' /app/dashboard.html
echo ""

echo "Contexto líneas 5145-5155:"
docker exec $container sed -n '5145,5155p' /app/dashboard.html
echo ""

# Verificar si hay caracteres especiales o problemas de codificación
echo "Verificando codificación alrededor de línea 5150:"
docker exec $container sed -n '5148,5152p' /app/dashboard.html | od -c | head -5
echo ""

# Verificar tamaño
size=$(docker exec $container stat -c%s /app/dashboard.html 2>/dev/null || docker exec $container stat -f%z /app/dashboard.html 2>/dev/null)
echo "Tamaño del archivo: $size bytes"
echo ""

# Verificar si hay problemas de sintaxis con node
echo "Verificando sintaxis básica (primeras 100 líneas después de línea 5100):"
docker exec $container sed -n '5100,5200p' /app/dashboard.html | head -20








