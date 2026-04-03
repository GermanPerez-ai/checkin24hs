#!/bin/bash
# Verificar servicios de WhatsApp en Docker Swarm

echo "=== VERIFICANDO SERVICIOS WHATSAPP EN DOCKER SWARM ==="
echo ""

# Verificar estado de los servicios
echo "📋 Estado de los servicios:"
docker service ls | grep whatsapp
echo ""

# Verificar tareas activas
echo "=== TAREAS ACTIVAS ==="
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    TASK_ID=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}" | head -n 1)
    
    if [ -n "$TASK_ID" ]; then
        echo "Task ID: $TASK_ID"
        
        # Obtener nombre del contenedor
        CONTAINER_NAME=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.Name}}.{{.ID}}" | head -n 1)
        echo "Container: $CONTAINER_NAME"
        
        # Obtener IP del contenedor
        CONTAINER_IP=$(docker inspect $CONTAINER_NAME --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -n 1)
        
        if [ -n "$CONTAINER_IP" ]; then
            echo "IP: $CONTAINER_IP"
            PORT="300${i}"
            echo "Probando http://${CONTAINER_IP}:${PORT}/api/qr?card=${i}..."
            
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://${CONTAINER_IP}:${PORT}/api/qr?card=${i} 2>&1)
            echo "Respuesta: HTTP $RESPONSE"
            
            if [ "$RESPONSE" = "200" ]; then
                echo "✅ Servicio responde correctamente"
                # Obtener respuesta completa
                echo "Respuesta completa:"
                curl -s http://${CONTAINER_IP}:${PORT}/api/qr?card=${i} | head -5
            elif [ "$RESPONSE" = "404" ]; then
                echo "⚠️ Ruta no encontrada"
                echo "Probando ruta raíz /..."
                ROOT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 http://${CONTAINER_IP}:${PORT}/ 2>&1)
                echo "Respuesta en /: HTTP $ROOT_RESPONSE"
            fi
        else
            echo "⚠️ No se pudo obtener IP del contenedor"
            echo "Intentando obtener VIP del servicio..."
            VIP=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}' 2>/dev/null | head -n 1 | cut -d/ -f1)
            if [ -n "$VIP" ]; then
                echo "VIP: $VIP"
                PORT="300${i}"
                echo "Probando http://${VIP}:${PORT}/api/qr?card=${i}..."
                RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://${VIP}:${PORT}/api/qr?card=${i} 2>&1)
                echo "Respuesta: HTTP $RESPONSE"
            fi
        fi
    else
        echo "⚠️ No se encontró tarea activa"
    fi
    
    echo ""
done

# Verificar acceso a través del puerto publicado
echo "=== VERIFICANDO ACCESO A TRAVÉS DE PUERTOS PUBLICADOS ==="
for i in 1 2 3 4; do
    PORT=$((3000 + i))
    echo "Probando http://localhost:${PORT}/api/qr?card=${i}..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:${PORT}/api/qr?card=${i} 2>&1)
    echo "Respuesta: HTTP $RESPONSE"
    
    if [ "$RESPONSE" = "200" ]; then
        echo "✅ Servicio accesible en puerto ${PORT}"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






