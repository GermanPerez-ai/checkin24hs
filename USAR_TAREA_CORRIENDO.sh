#!/bin/bash
# Usar la IP de la tarea que está corriendo en lugar del VIP

echo "=== ENCONTRANDO TAREAS CORRIENDO ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "=== $SERVICE_NAME ==="
    
    # Encontrar tarea corriendo
    RUNNING_TASK=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}\t{{.Name}}\t{{.Node}}" | grep -v "Pending" | head -n 1)
    
    if [ -n "$RUNNING_TASK" ]; then
        TASK_NAME=$(echo "$RUNNING_TASK" | awk '{print $2}')
        NODE=$(echo "$RUNNING_TASK" | awk '{print $3}')
        
        echo "Tarea corriendo: $TASK_NAME en nodo $NODE"
        
        # Obtener IP del contenedor en la red easypanel
        EASYPANEL_IP=$(docker inspect $TASK_NAME --format '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "easypanel"}}{{$v.IPAddress}}{{end}}{{end}}' 2>/dev/null)
        
        if [ -n "$EASYPANEL_IP" ]; then
            echo "IP en easypanel: $EASYPANEL_IP"
            
            # Probar conexión desde Traefik
            TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
            if [ -n "$TRAEFIK_CONTAINER" ]; then
                echo "Probando desde Traefik..."
                RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://${EASYPANEL_IP}:${PORT}/api/qr?card=${i} 2>&1)
                
                if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
                    echo "✅ Servicio responde correctamente"
                    echo "Configurando Traefik para usar esta IP..."
                    
                    docker service update \
                        --label-rm "traefik.http.services.${SERVICE_NAME}.loadbalancer.server" \
                        --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${EASYPANEL_IP}:${PORT}" \
                        $SERVICE_NAME 2>&1 | head -3
                    
                    echo "   ✅ Configurado para http://${EASYPANEL_IP}:${PORT}"
                else
                    echo "❌ Servicio no responde desde Traefik"
                    echo "Error: $RESPONSE"
                fi
            fi
        else
            echo "⚠️ No se encontró IP en la red easypanel"
        fi
    else
        echo "⚠️ No se encontró tarea corriendo"
    fi
    
    echo ""
done

echo "⏳ Espera 10 segundos..."
sleep 10

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






