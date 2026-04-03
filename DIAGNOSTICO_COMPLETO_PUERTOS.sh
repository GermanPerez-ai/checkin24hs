#!/bin/bash
# Diagnóstico completo del problema de puertos

echo "=== DIAGNÓSTICO COMPLETO DE PUERTOS ==="
echo ""

# Verificar qué está usando los puertos
echo "=== PUERTOS EN USO ==="
for port in 3001 3002 3003 3004; do
    echo "Puerto $port:"
    
    # Verificar con docker ps
    CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep ":$port->\|:$port/" | awk '{print $1}' | head -n 1)
    if [ -n "$CONTAINER" ]; then
        echo "   Usado por contenedor Docker: $CONTAINER"
        docker ps --format "{{.Names}}\t{{.Ports}}" | grep ":$port"
    fi
    
    # Verificar con netstat/ss
    if command -v ss >/dev/null 2>&1; then
        SS_OUTPUT=$(ss -tuln | grep ":$port ")
        if [ -n "$SS_OUTPUT" ]; then
            echo "   Puerto en uso en el sistema:"
            echo "$SS_OUTPUT"
        fi
    fi
    
    echo ""
done

echo "=== CONFIGURACIÓN DE SERVICIOS ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    PORT=$((3000 + i))
    
    echo "=== $SERVICE_NAME ==="
    
    # Ver puertos publicados
    echo "Puertos publicados:"
    docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}/{{.TargetPort}}/{{.Protocol}} ({{.PublishMode}}){{"\n"}}{{end}}' 2>/dev/null || echo "   (sin puertos)"
    
    # Ver configuración de puertos en el spec
    echo "Configuración de puertos en spec:"
    docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.ContainerSpec}}{{end}}{{range .Spec.TaskTemplate.Placement}}{{end}}{{range .Spec.EndpointSpec.Ports}}{{.PublishedPort}}/{{.TargetPort}}/{{.Protocol}} ({{.PublishMode}}){{"\n"}}{{end}}' 2>/dev/null || echo "   (sin configuración)"
    
    echo ""
done

echo "=== SOLUCIÓN: ESCALAR SERVICIOS A 0 Y LUEGO A 1 ==="
echo ""
echo "Esto forzará la recreación de los servicios sin puertos:"
echo ""

read -p "¿Quieres escalar los servicios a 0 y luego a 1? (s/n) " respuesta

if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
    echo ""
    echo "Escalando servicios a 0..."
    
    for i in 1 2 3 4; do
        SERVICE_NAME="checkin24hs_whatsapp"
        if [ $i -gt 1 ]; then
            SERVICE_NAME="${SERVICE_NAME}${i}"
        fi
        
        docker service scale ${SERVICE_NAME}=0
    done
    
    echo "Esperando 10 segundos..."
    sleep 10
    
    echo ""
    echo "Escalando servicios a 1..."
    
    for i in 1 2 3 4; do
        SERVICE_NAME="checkin24hs_whatsapp"
        if [ $i -gt 1 ]; then
            SERVICE_NAME="${SERVICE_NAME}${i}"
        fi
        
        docker service scale ${SERVICE_NAME}=1
    done
    
    echo "Esperando 30 segundos para que se inicien..."
    sleep 30
    
    echo ""
    echo "=== VERIFICANDO ESTADO ==="
    docker service ps checkin24hs_whatsapp | head -5
fi

echo ""
echo "✅ Diagnóstico completado"
echo ""






