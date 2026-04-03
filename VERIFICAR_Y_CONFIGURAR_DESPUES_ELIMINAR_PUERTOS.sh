#!/bin/bash
# Verificar y configurar después de eliminar puertos publicados

echo "=== VERIFICANDO ESTADO DE SERVICIOS ==="
echo ""

# Verificar que los servicios se reiniciaron
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    
    # Ver estado de tareas
    RUNNING_TASKS=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}\t{{.Name}}\t{{.CurrentState}}" | grep -v "Pending")
    
    if [ -n "$RUNNING_TASKS" ]; then
        echo "Tareas corriendo:"
        echo "$RUNNING_TASKS" | head -3
        
        # Obtener primera tarea corriendo
        TASK_NAME=$(echo "$RUNNING_TASKS" | head -n 1 | awk '{print $2}')
        
        if [ -n "$TASK_NAME" ]; then
            echo "Usando tarea: $TASK_NAME"
            
            # Obtener todas las IPs del contenedor
            echo "IPs del contenedor:"
            docker inspect $TASK_NAME --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{"\n"}}{{end}}' 2>/dev/null
            
            # Obtener IP en easypanel específicamente
            EASYPANEL_IP=$(docker inspect $TASK_NAME --format '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "easypanel"}}{{$v.IPAddress}}{{end}}{{end}}' 2>/dev/null)
            
            if [ -z "$EASYPANEL_IP" ]; then
                # Intentar obtener cualquier IP de la red easypanel
                EASYPANEL_IP=$(docker inspect $TASK_NAME --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{end}}' 2>/dev/null | head -n 1)
            fi
            
            if [ -n "$EASYPANEL_IP" ]; then
                echo "IP encontrada: $EASYPANEL_IP"
            else
                echo "⚠️ No se encontró IP"
            fi
        fi
    else
        echo "⚠️ No hay tareas corriendo (todas están en Pending)"
    fi
    
    echo ""
done

echo "=== ESPERANDO A QUE LOS SERVICIOS SE REINICIEN ==="
echo ""
echo "Si eliminaste los puertos publicados, los servicios deberían reiniciarse automáticamente."
echo "Espera 30 segundos y luego verifica:"
echo ""
echo "docker service ps checkin24hs_whatsapp | head -5"
echo ""

# Esperar un momento
sleep 5

echo "=== VERIFICANDO NUEVAMENTE ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    # Buscar tarea corriendo
    RUNNING_TASK=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}\t{{.Name}}\t{{.CurrentState}}" | grep "Running" | head -n 1)
    
    if [ -n "$RUNNING_TASK" ]; then
        TASK_NAME=$(echo "$RUNNING_TASK" | awk '{print $2}')
        PORT=$((3000 + i))
        
        echo "=== $SERVICE_NAME ==="
        echo "Tarea corriendo: $TASK_NAME"
        
        # Obtener IP - probar diferentes métodos
        EASYPANEL_IP=$(docker inspect $TASK_NAME --format '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "easypanel"}}{{$v.IPAddress}}{{end}}{{end}}' 2>/dev/null)
        
        if [ -z "$EASYPANEL_IP" ]; then
            # Obtener primera IP disponible
            EASYPANEL_IP=$(docker inspect $TASK_NAME --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{end}}' 2>/dev/null | grep -v "^$" | head -n 1)
        fi
        
        if [ -n "$EASYPANEL_IP" ] && [ "$EASYPANEL_IP" != "" ]; then
            echo "IP: $EASYPANEL_IP"
            
            # Probar desde Traefik
            TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
            if [ -n "$TRAEFIK_CONTAINER" ]; then
                echo "Probando desde Traefik..."
                RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://${EASYPANEL_IP}:${PORT}/api/qr?card=${i} 2>&1)
                
                if [ $? -eq 0 ] && [ -n "$RESPONSE" ] && ! echo "$RESPONSE" | grep -q "can't connect\|bad address\|unreachable"; then
                    echo "✅ Servicio responde correctamente"
                    echo "Configurando Traefik..."
                    
                    docker service update \
                        --label-rm "traefik.http.services.${SERVICE_NAME}.loadbalancer.server" \
                        --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${EASYPANEL_IP}:${PORT}" \
                        $SERVICE_NAME 2>&1 | head -3
                    
                    echo "   ✅ Configurado"
                else
                    echo "❌ Servicio no responde desde Traefik"
                    echo "   Error: $RESPONSE"
                fi
            fi
        else
            echo "⚠️ No se pudo obtener IP"
        fi
    else
        echo "⚠️ No hay tarea corriendo para $SERVICE_NAME"
    fi
    
    echo ""
done

echo "⏳ Espera 15 segundos..."
sleep 15

echo ""
echo "=== PROBANDO CONEXIÓN HTTPS ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "Probando https://${SUBDOMAIN}/api/qr?card=${i}..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 - ¡Funciona!"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






