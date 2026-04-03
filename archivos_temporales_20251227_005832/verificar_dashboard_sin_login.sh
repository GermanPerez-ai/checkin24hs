#!/bin/bash

echo "=========================================="
echo "Verificación del Dashboard Sin Login"
echo "=========================================="
echo ""

# 1. Verificar que el servicio está corriendo
echo "1. Estado del servicio:"
docker service ls | grep dashboard
echo ""

# 2. Verificar que el archivo dashboard.html se actualizó
echo "2. Verificando archivo dashboard.html en el contenedor:"
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "   ⚠️  No se encontró contenedor corriendo. Esperando 10 segundos..."
    sleep 10
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    echo "   Tamaño del archivo:"
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null || echo "   ⚠️  No se encontró dashboard.html en /app/"
    echo ""
    echo "   Verificando que NO tenga el contenedor de login:"
    docker exec $CONTAINER_ID grep -c "login-container" /app/dashboard.html 2>/dev/null || echo "   ✅ No se encontró 'login-container'"
    echo ""
else
    echo "   ⚠️  No se pudo encontrar el contenedor"
fi

# 3. Ver logs del servicio
echo "3. Últimos logs del servicio (últimas 20 líneas):"
docker service logs checkin24hs_dashboard --tail 20 2>&1 | tail -20
echo ""

# 4. Probar acceso local
echo "4. Probando acceso local al dashboard:"
TASK_ID=$(docker service ps checkin24hs_dashboard --no-trunc -q | head -1)
if [ ! -z "$TASK_ID" ]; then
    NODE_ID=$(docker service ps checkin24hs_dashboard --no-trunc --format "{{.Node}}" | head -1)
    echo "   Tarea: $TASK_ID"
    echo "   Nodo: $NODE_ID"
fi

# Probar con curl
echo ""
echo "5. Probando respuesta HTTP:"
curl -s -I http://localhost:3000 2>&1 | head -5
echo ""

# 6. Verificar que el HTML no contiene el login
echo "6. Verificando contenido HTML (primeras 50 líneas):"
curl -s http://localhost:3000 2>&1 | head -50 | grep -i "login\|authenticated" | head -5
echo ""

# 7. Verificar acceso vía dominio (si está configurado)
echo "7. Probando acceso vía dominio:"
curl -s -I http://dashboard.checkin24hs.com 2>&1 | head -5
echo ""

echo "=========================================="
echo "Verificación completada"
echo "=========================================="
echo ""
echo "Si ves 'HTTP/1.1 200 OK' y el HTML no contiene 'login-container',"
echo "entonces el dashboard debería estar funcionando sin login."
echo ""
echo "Abre en tu navegador:"
echo "  - http://72.61.58.240:3000"
echo "  - http://dashboard.checkin24hs.com"
echo ""

