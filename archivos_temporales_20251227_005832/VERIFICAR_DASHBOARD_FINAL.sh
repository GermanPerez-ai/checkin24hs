#!/bin/bash

echo "=========================================="
echo "Verificación Final del Dashboard"
echo "=========================================="
echo ""

# 1. Verificar el servicio
echo "1. Estado del servicio:"
docker service ps checkin24hs_dashboard --no-trunc | head -3
echo ""

# 2. Encontrar el contenedor actual
echo "2. Contenedor actual:"
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   ID: $CONTAINER_ID"
    echo "   Archivo dashboard.html:"
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null || echo "   ⚠️  No encontrado"
    echo ""
    echo "   Tamaño del archivo:"
    docker exec $CONTAINER_ID wc -c /app/dashboard.html 2>/dev/null || echo "   0"
    echo ""
else
    echo "   ⚠️  No se encontró contenedor"
fi

# 3. Probar acceso HTTP
echo "3. Probando acceso HTTP:"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
echo "   Código HTTP: $HTTP_RESPONSE"
echo ""

# 4. Ver contenido HTML servido
echo "4. Tamaño del HTML servido:"
HTML_SIZE=$(curl -s http://localhost:3000 | wc -c)
echo "   $HTML_SIZE bytes"
echo ""

# 5. Verificar si tiene login-container
echo "5. Verificando login-container:"
LOGIN_COUNT=$(curl -s http://localhost:3000 | grep -o "login-container" | wc -l)
if [ "$LOGIN_COUNT" -eq "0" ]; then
    echo "   ✅ No se encontró login-container"
else
    echo "   ⚠️  Se encontraron $LOGIN_COUNT ocurrencias de login-container"
fi
echo ""

# 6. Ver primeras líneas del HTML
echo "6. Primeras 30 líneas del HTML servido:"
curl -s http://localhost:3000 | head -30
echo ""

echo "=========================================="
echo "Verificación completada"
echo "=========================================="
