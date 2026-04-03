#!/bin/bash

# Script para diagnosticar el error 404 del webmail

SERVICE_NAME="checkin24hs_webmail"

echo "=== Diagnóstico del Webmail ==="

# 1. Ver estado del servicio
echo ""
echo "1. Estado del servicio webmail:"
docker service ps $SERVICE_NAME --no-trunc | head -5

# 2. Ver logs recientes
echo ""
echo "2. Últimos logs del webmail:"
docker service logs $SERVICE_NAME --tail 30

# 3. Ver configuración de Traefik
echo ""
echo "3. Configuración de Traefik para webmail:"
docker service inspect $SERVICE_NAME --format '{{json .Spec.Labels}}' | grep -i traefik || echo "No se encontraron etiquetas de Traefik"

# 4. Ver puertos del servicio
echo ""
echo "4. Puertos del servicio:"
docker service inspect $SERVICE_NAME --format '{{json .Endpoint.Ports}}' | jq '.' 2>/dev/null || docker service inspect $SERVICE_NAME --format '{{json .Endpoint.Ports}}'

# 5. Verificar contenedores corriendo
echo ""
echo "5. Contenedores del webmail:"
docker ps --filter "name=webmail" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"

# 6. Verificar conectividad interna
echo ""
echo "6. Verificando conectividad interna:"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Verificando respuesta del servidor:"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:80 2>&1 | head -10 || echo "No se pudo conectar al servidor interno"
    
    echo ""
    echo "Archivos en el contenedor:"
    docker exec $CONTAINER_ID ls -lah / 2>&1 | head -20
else
    echo "No se encontró contenedor corriendo"
fi

# 7. Ver logs de Traefik relacionados con webmail
echo ""
echo "7. Logs de Traefik relacionados con webmail:"
docker service logs traefik --tail 50 2>&1 | grep -i webmail | tail -10 || echo "No se encontraron referencias a webmail en Traefik"

echo ""
echo "=== Diagnóstico completado ==="






