#!/bin/bash

echo "=========================================="
echo "Copiando dashboard.html al contenedor"
echo "=========================================="
echo ""

# 1. Verificar que el archivo existe localmente
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: dashboard.html no existe en el directorio actual"
    exit 1
fi

echo "✅ Archivo dashboard.html encontrado"
ls -lh dashboard.html
echo ""

# 2. Encontrar el contenedor del servicio
echo "2. Buscando contenedor del servicio..."
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: No se encontró contenedor corriendo"
    echo "   Intentando obtener el ID de la tarea..."
    TASK_ID=$(docker service ps checkin24hs_dashboard -q --no-trunc | head -1)
    if [ ! -z "$TASK_ID" ]; then
        CONTAINER_ID=$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $TASK_ID 2>/dev/null)
    fi
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: No se pudo encontrar el contenedor"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 3. Hacer backup del archivo actual
echo "3. Haciendo backup del archivo actual..."
docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "   (No se pudo hacer backup, continuando...)"
echo ""

# 4. Copiar el archivo al contenedor
echo "4. Copiando dashboard.html al contenedor..."
docker cp dashboard.html ${CONTAINER_ID}:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente"
else
    echo "❌ Error al copiar el archivo"
    exit 1
fi
echo ""

# 5. Verificar que se copió correctamente
echo "5. Verificando archivo en el contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html
echo ""

# 6. Verificar tamaño
LOCAL_SIZE=$(wc -c < dashboard.html)
REMOTE_SIZE=$(docker exec $CONTAINER_ID wc -c < /app/dashboard.html 2>/dev/null || echo "0")

echo "   Tamaño local: $LOCAL_SIZE bytes"
echo "   Tamaño remoto: $REMOTE_SIZE bytes"

if [ "$LOCAL_SIZE" -eq "$REMOTE_SIZE" ]; then
    echo "✅ Tamaños coinciden"
else
    echo "⚠️  Los tamaños no coinciden, pero continuando..."
fi
echo ""

# 7. Reiniciar el servicio para aplicar cambios
echo "6. Reiniciando el servicio..."
docker service update --force checkin24hs_dashboard

if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
    echo ""
    echo "Esperando 10 segundos para que el servicio se inicie..."
    sleep 10
    echo ""
    echo "7. Verificando que el servicio está corriendo:"
    docker service ps checkin24hs_dashboard --no-trunc | head -5
else
    echo "❌ Error al reiniciar el servicio"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Ahora prueba acceder a:"
echo "  - http://72.61.58.240:3000"
echo "  - http://dashboard.checkin24hs.com"
echo ""

