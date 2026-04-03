#!/bin/bash

echo "=========================================="
echo "Verificación del Contenido HTML"
echo "=========================================="
echo ""

# 1. Ver qué archivo HTML se está sirviendo
echo "1. Contenido HTML completo que se está sirviendo:"
echo "----------------------------------------"
curl -s http://localhost:3000 | head -100
echo ""
echo "----------------------------------------"
echo ""

# 2. Ver tamaño del archivo
echo "2. Tamaño del archivo HTML servido:"
curl -s http://localhost:3000 | wc -c
echo ""

# 3. Verificar dentro del contenedor
echo "3. Verificando archivo dentro del contenedor:"
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    echo "   Archivos en /app/:"
    docker exec $CONTAINER_ID ls -lh /app/*.html 2>/dev/null || echo "   No se encontraron archivos HTML"
    echo ""
    echo "   Tamaño de dashboard.html:"
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null
    echo ""
    echo "   Primeras 20 líneas de dashboard.html:"
    docker exec $CONTAINER_ID head -20 /app/dashboard.html 2>/dev/null
else
    echo "   ⚠️  No se encontró contenedor"
fi

echo ""
echo "=========================================="

