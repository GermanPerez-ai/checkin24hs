#!/bin/bash

echo "=========================================="
echo "COPIAR ARCHIVOS AL CONTENEDOR DOCKER"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar que los archivos existen en el servidor
echo "1. Verificando archivos en el servidor:"
ls -lh dashboard.html supabase-client.js supabase-config.js 2>/dev/null
echo ""

# 2. Buscar el contenedor ACTUAL del servicio
echo "2. Buscando contenedor del servicio..."
SERVICE_NAME="checkin24hs_dashboard"

# Obtener el ID de la tarea actual
TASK_ID=$(docker service ps $SERVICE_NAME --no-trunc -q --filter "desired-state=running" | head -1)

if [ -z "$TASK_ID" ]; then
    echo "❌ No se encontró tarea corriendo del servicio"
    docker service ls | grep dashboard
    exit 1
fi

echo "   Tarea encontrada: $TASK_ID"

# Obtener el ID del contenedor desde la tarea
CONTAINER_ID=$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $TASK_ID 2>/dev/null)

if [ -z "$CONTAINER_ID" ] || [ "$CONTAINER_ID" = "<no value>" ]; then
    # Intentar método alternativo: buscar por nombre del servicio
    CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar el contenedor"
    echo "   Intentando método alternativo..."
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    echo "   Contenedores corriendo:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    exit 1
fi

echo "   ✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 3. Verificar archivos actuales en el contenedor
echo "3. Archivos actuales en el contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html /app/supabase-client.js /app/supabase-config.js 2>/dev/null || echo "   ⚠️  Algunos archivos no encontrados"
echo ""

# 4. Copiar archivos al contenedor
echo "4. Copiando archivos al contenedor..."

echo "   Copiando dashboard.html..."
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html
if [ $? -eq 0 ]; then
    echo "   ✅ dashboard.html copiado"
else
    echo "   ❌ Error al copiar dashboard.html"
    exit 1
fi

echo "   Copiando supabase-client.js..."
docker cp supabase-client.js $CONTAINER_ID:/app/supabase-client.js
if [ $? -eq 0 ]; then
    echo "   ✅ supabase-client.js copiado"
else
    echo "   ⚠️  Error al copiar supabase-client.js"
fi

if [ -f "supabase-config.js" ]; then
    echo "   Copiando supabase-config.js..."
    docker cp supabase-config.js $CONTAINER_ID:/app/supabase-config.js
    if [ $? -eq 0 ]; then
        echo "   ✅ supabase-config.js copiado"
    else
        echo "   ⚠️  Error al copiar supabase-config.js"
    fi
fi

echo ""

# 5. Verificar que se copiaron correctamente
echo "5. Verificando archivos copiados:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html /app/supabase-client.js /app/supabase-config.js 2>/dev/null

echo ""

# 6. Comparar tamaños
echo "6. Comparando tamaños:"
LOCAL_DASHBOARD=$(ls -lh dashboard.html | awk '{print $5}')
CONTAINER_DASHBOARD=$(docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null | awk '{print $5}')
echo "   Local dashboard.html: $LOCAL_DASHBOARD"
echo "   Contenedor dashboard.html: $CONTAINER_DASHBOARD"

if [ "$LOCAL_DASHBOARD" = "$CONTAINER_DASHBOARD" ]; then
    echo "   ✅ Los tamaños coinciden"
else
    echo "   ⚠️  Los tamaños NO coinciden - puede haber un problema"
fi

echo ""

# 7. IMPORTANTE: Reiniciar el servicio para que use los nuevos archivos
echo "7. Reiniciando servicio para aplicar cambios..."
docker service update --force $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
else
    echo "❌ Error al reiniciar el servicio"
    exit 1
fi

echo ""
echo "Esperando 25 segundos para que el servicio se inicie completamente..."
sleep 25

echo ""

# 8. Verificar nuevo contenedor
echo "8. Verificando nuevo contenedor después del reinicio..."
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ] && [ "$NEW_CONTAINER_ID" != "$CONTAINER_ID" ]; then
    echo "   ⚠️  Se creó un nuevo contenedor: $NEW_CONTAINER_ID"
    echo "   Necesitas copiar los archivos de nuevo al nuevo contenedor"
    echo ""
    echo "   Ejecuta estos comandos:"
    echo "   docker cp dashboard.html $NEW_CONTAINER_ID:/app/dashboard.html"
    echo "   docker cp supabase-client.js $NEW_CONTAINER_ID:/app/supabase-client.js"
    echo "   docker cp supabase-config.js $NEW_CONTAINER_ID:/app/supabase-config.js"
else
    echo "   ✅ Mismo contenedor o servicio estable"
fi

echo ""

# 9. Probar acceso
echo "9. Probando acceso HTTP:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
HTML_SIZE=$(curl -s http://localhost:3000 | wc -c)

echo "   Código HTTP: $HTTP_CODE"
echo "   Tamaño HTML: $HTML_SIZE bytes"

if [ "$HTTP_CODE" = "200" ] && [ "$HTML_SIZE" -gt "1000000" ]; then
    echo "   ✅ Servidor respondiendo correctamente"
else
    echo "   ⚠️  Puede haber un problema (HTTP: $HTTP_CODE, Tamaño: $HTML_SIZE)"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "IMPORTANTE: Si el servicio se reinició y creó un nuevo contenedor,"
echo "necesitas copiar los archivos de nuevo al nuevo contenedor."
echo ""
echo "Prueba acceder a:"
echo "  - http://72.61.58.240:3000"
echo "  - http://dashboard.checkin24hs.com"
echo ""

