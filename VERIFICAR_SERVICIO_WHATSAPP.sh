#!/bin/bash
# Script para verificar el estado del servicio de WhatsApp

echo "=========================================="
echo "VERIFICAR SERVICIO DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Verificar servicios Docker Swarm
echo "=== SERVICIOS DOCKER SWARM ==="
echo ""
docker service ls | grep whatsapp
echo ""

# 2. Verificar detalles del servicio
echo "=== DETALLES DEL SERVICIO ==="
echo ""
SERVICE_NAME=$(docker service ls | grep whatsapp | awk '{print $2}' | head -1)
if [ -n "$SERVICE_NAME" ]; then
    echo "Servicio: $SERVICE_NAME"
    echo ""
    docker service ps $SERVICE_NAME --no-trunc | head -10
    echo ""
else
    echo "⚠️ No se encontró servicio de WhatsApp"
fi
echo ""

# 3. Verificar contenedores actuales
echo "=== CONTENEDORES ACTUALES ==="
echo ""
echo "Contenedores corriendo:"
docker ps | grep whatsapp
echo ""

echo "Últimos contenedores (incluyendo detenidos):"
docker ps -a | grep whatsapp | head -5
echo ""

# 4. Verificar logs del último contenedor que falló
echo "=== LOGS DEL ÚLTIMO CONTENEDOR QUE FALLÓ ==="
echo ""
LAST_CONTAINER=$(docker ps -a | grep whatsapp | grep "Exited\|Dead" | head -1 | awk '{print $1}')
if [ -n "$LAST_CONTAINER" ]; then
    echo "Último contenedor que falló: $LAST_CONTAINER"
    echo ""
    echo "Últimas 30 líneas de logs:"
    docker logs $LAST_CONTAINER --tail 30 2>&1
    echo ""
    
    echo "Errores encontrados:"
    docker logs $LAST_CONTAINER --tail 100 2>&1 | grep -iE "error|fatal|exception|crash" | tail -10
    echo ""
else
    echo "⚠️ No se encontró contenedor que haya fallado"
fi
echo ""

# 5. Verificar si hay un contenedor en estado "Created"
echo "=== CONTENEDOR EN ESTADO 'Created' ==="
echo ""
CREATED_CONTAINER=$(docker ps -a | grep whatsapp | grep "Created" | head -1 | awk '{print $1}')
if [ -n "$CREATED_CONTAINER" ]; then
    echo "Contenedor en estado Created: $CREATED_CONTAINER"
    echo ""
    echo "Intentando iniciar..."
    docker start $CREATED_CONTAINER
    sleep 3
    echo ""
    echo "Estado después de iniciar:"
    docker ps | grep $CREATED_CONTAINER
    echo ""
else
    echo "✅ No hay contenedores en estado Created"
fi
echo ""

echo "=========================================="
echo "RECOMENDACIONES"
echo "=========================================="
echo ""
if [ -n "$SERVICE_NAME" ]; then
    echo "Para reiniciar el servicio:"
    echo "  docker service update --force $SERVICE_NAME"
    echo ""
fi
echo "Para ver logs en tiempo real cuando esté corriendo:"
echo "  docker logs -f \$(docker ps | grep whatsapp | awk '{print \$1}' | head -1)"
echo ""
