#!/bin/bash

# Script para ver logs del servicio WhatsApp desde el servidor
# Ejecutar desde cualquier directorio

echo "=========================================="
echo "📋 VER LOGS DEL SERVICIO WHATSAPP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Ver contenedores del servicio
echo "1️⃣ Contenedores del servicio:"
echo "----------------------------------------"
docker ps --filter "name=whatsapp" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
echo ""

# 2. Obtener ID del contenedor
CONTAINER_ID=$(docker ps --filter "name=whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    echo ""
    echo "Intentando buscar por servicio Docker Swarm..."
    
    # Buscar por servicio Docker Swarm
    TASK_ID=$(docker service ps $SERVICE_NAME --no-trunc -f "desired-state=running" --format "{{.ID}}" | head -1)
    
    if [ -z "$TASK_ID" ]; then
        echo "❌ No se encontró tarea del servicio"
        exit 1
    fi
    
    echo "✅ Tarea encontrada: $TASK_ID"
    echo ""
    echo "Para ver logs de un servicio Docker Swarm, usa:"
    echo "  docker service logs $SERVICE_NAME --tail 100 -f"
    echo ""
    exit 0
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 3. Mostrar opciones
echo "2️⃣ Opciones para ver logs:"
echo "----------------------------------------"
echo ""
echo "📋 Ver últimas 50 líneas:"
echo "   docker logs $CONTAINER_ID --tail 50"
echo ""
echo "📋 Ver últimas 100 líneas:"
echo "   docker logs $CONTAINER_ID --tail 100"
echo ""
echo "📋 Ver logs en tiempo real (seguimiento):"
echo "   docker logs $CONTAINER_ID -f"
echo ""
echo "📋 Ver logs desde el inicio:"
echo "   docker logs $CONTAINER_ID"
echo ""
echo "📋 Ver logs con timestamps:"
echo "   docker logs $CONTAINER_ID --timestamps --tail 100"
echo ""
echo "📋 Ver logs desde una fecha específica:"
echo "   docker logs $CONTAINER_ID --since 10m  (últimos 10 minutos)"
echo "   docker logs $CONTAINER_ID --since 1h   (última hora)"
echo ""

# 4. Mostrar logs recientes
echo "3️⃣ Mostrando últimas 50 líneas de logs:"
echo "----------------------------------------"
docker logs $CONTAINER_ID --tail 50 --timestamps

echo ""
echo "=========================================="
echo "💡 Para seguir los logs en tiempo real, ejecuta:"
echo "   docker logs $CONTAINER_ID -f"
echo "=========================================="
echo ""
