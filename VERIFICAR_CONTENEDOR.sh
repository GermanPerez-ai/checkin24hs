#!/bin/bash

echo "🔍 Verificando que el archivo en el contenedor tiene la corrección..."
echo ""

# Obtener un contenedor activo
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró ningún contenedor activo"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER"
echo ""

# Verificar que el archivo tiene la corrección
echo "=== Verificando window.buildServerURL en el contenedor ==="
docker exec $CONTAINER grep -n "window.buildServerURL" /app/dashboard.html 2>/dev/null

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ El archivo en el contenedor tiene la corrección"
else
    echo ""
    echo "❌ El archivo en el contenedor NO tiene la corrección"
    echo "   Necesitas copiar el archivo nuevamente"
fi

echo ""
echo "=== Verificando window.getServerURL en el contenedor ==="
docker exec $CONTAINER grep -n "window.getServerURL" /app/dashboard.html 2>/dev/null

echo ""
echo "✅ Verificación completada"








