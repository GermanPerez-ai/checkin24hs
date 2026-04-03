#!/bin/bash
# Forzar remoción de puertos publicados de los servicios

echo "=== FORZANDO REMOCIÓN DE PUERTOS PUBLICADOS ==="
echo ""

# Verificar qué está usando los puertos
echo "=== VERIFICANDO PUERTOS EN USO ==="
for port in 3001 3002 3003 3004; do
    echo "Puerto $port:"
    CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep ":$port->" | awk '{print $1}' | head -n 1)
    if [ -n "$CONTAINER" ]; then
        echo "   Usado por contenedor: $CONTAINER"
    else
        echo "   No usado por contenedores Docker"
    fi
    
    # Verificar con netstat/ss
    if command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep ":$port " && echo "   Puerto en uso en el sistema"
    elif command -v ss >/dev/null 2>&1; then
        ss -tuln | grep ":$port " && echo "   Puerto en uso en el sistema"
    fi
    echo ""
done

echo "=== REMOVIENDO PUERTOS PUBLICADOS DE LOS SERVICIOS ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "Removiendo puerto ${PORT} de $SERVICE_NAME..."
    
    # Intentar remover puerto publicado
    docker service update \
        --publish-rm ${PORT}:${PORT} \
        $SERVICE_NAME 2>&1 | head -5
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Puerto removido"
    else
        echo "   ⚠️ Error removiendo puerto (puede que ya no esté publicado)"
    fi
    
    echo ""
done

echo "⏳ Espera 30 segundos para que los servicios se reinicien..."
sleep 30

echo ""
echo "=== VERIFICANDO ESTADO DE SERVICIOS ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    
    # Verificar puertos publicados
    PORTS=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}/{{.TargetPort}}/{{.Protocol}}{{","}}{{end}}' 2>/dev/null)
    if [ -n "$PORTS" ] && [ "$PORTS" != "," ]; then
        echo "Puertos publicados: $PORTS"
    else
        echo "✅ No tiene puertos publicados"
    fi
    
    # Ver estado de tareas
    RUNNING_TASK=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}\t{{.Name}}\t{{.CurrentState}}" | grep "Running" | head -n 1)
    if [ -n "$RUNNING_TASK" ]; then
        echo "✅ Tarea corriendo: $(echo "$RUNNING_TASK" | awk '{print $2}')"
    else
        echo "⚠️ No hay tareas corriendo"
        docker service ps $SERVICE_NAME --no-trunc | head -3
    fi
    
    echo ""
done

echo "=== CONFIGURANDO TRAEFIK CON NOMBRE DE SERVICIO ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "Configurando $SERVICE_NAME..."
    
    docker service update \
        --label-rm "traefik.http.services.${SERVICE_NAME}.loadbalancer.server" \
        --label-add "traefik.http.services.${SERVICE_NAME}.loadbalancer.server=http://${SERVICE_NAME}:${PORT}" \
        $SERVICE_NAME 2>&1 | head -3
    
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
        echo "✅ HTTP 200 - ¡Funciona correctamente!"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 - Ruta no encontrada"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Bad Gateway"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "✅ Verificación completada"
echo ""






