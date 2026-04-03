#!/bin/bash

# Script para diagnosticar Gateway Timeout del webmail

SERVICE_NAME="checkin24hs_webmail"

echo "=== Diagnóstico de Gateway Timeout ==="

# 1. Ver estado del servicio
echo ""
echo "1. Estado del servicio:"
docker service ps $SERVICE_NAME --no-trunc | head -5

# 2. Ver logs recientes del webmail
echo ""
echo "2. Últimos logs del webmail (últimas 50 líneas):"
docker service logs $SERVICE_NAME --tail 50

# 3. Verificar si el contenedor responde
echo ""
echo "3. Verificando respuesta del contenedor:"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Verificando proceso Apache:"
    docker exec $CONTAINER_ID ps aux | grep apache | head -5
    
    echo ""
    echo "Verificando respuesta HTTP (desde dentro del contenedor):"
    docker exec $CONTAINER_ID sh -c "timeout 5 wget -qO- http://localhost:80 2>&1 | head -10" || echo "No se pudo conectar internamente"
    
    echo ""
    echo "Verificando uso de recursos:"
    docker stats $CONTAINER_ID --no-stream --format "CPU: {{.CPUPerc}} | Memoria: {{.MemUsage}}"
else
    echo "No se encontró contenedor corriendo"
fi

# 4. Verificar conectividad desde Traefik
echo ""
echo "4. Verificando conectividad desde Traefik:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo "Intentando conectar al webmail desde Traefik:"
    docker exec $TRAEFIK_CONTAINER sh -c "timeout 5 wget -qO- http://checkin24hs_webmail:80 2>&1 | head -10" || echo "No se pudo conectar desde Traefik"
fi

# 5. Ver logs de Traefik relacionados con webmail
echo ""
echo "5. Logs de Traefik relacionados con webmail (últimas 30 líneas):"
docker service logs traefik --tail 200 2>&1 | grep -i webmail | tail -30

# 6. Verificar configuración de timeout en Traefik
echo ""
echo "6. Verificando configuración de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}' | grep -i timeout || echo "No se encontró configuración de timeout específica"

# 7. Verificar recursos del servicio
echo ""
echo "7. Recursos del servicio:"
docker service inspect $SERVICE_NAME --format '{{json .Spec.TaskTemplate.Resources}}' | jq '.' 2>/dev/null || docker service inspect $SERVICE_NAME --format '{{json .Spec.TaskTemplate.Resources}}'

echo ""
echo "=== Diagnóstico completado ==="






