#!/bin/bash

# Script para verificar si Traefik detecta el webmail

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== Verificando detección de Traefik ==="

# 1. Verificar etiquetas
echo ""
echo "1. Etiquetas de Traefik:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

# 2. Verificar que el contenedor responde (usando curl en lugar de wget)
echo ""
echo "2. Verificando respuesta del servidor:"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    # Intentar con curl (más común en contenedores)
    docker exec $CONTAINER_ID curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>&1 || echo "curl no disponible, verificando proceso..."
    echo ""
    echo "Proceso Apache corriendo:"
    docker exec $CONTAINER_ID ps aux | grep apache | head -3 || echo "No se encontró proceso Apache"
else
    echo "No se encontró contenedor corriendo"
fi

# 3. Verificar red del servicio
echo ""
echo "3. Redes del servicio webmail:"
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# 4. Verificar red de Traefik
echo ""
echo "4. Redes de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# 5. Ver todos los logs de Traefik (sin filtrar)
echo ""
echo "5. Últimos logs de Traefik (sin filtrar):"
docker service logs traefik --tail 50 2>&1 | tail -20

# 6. Verificar si Traefik puede alcanzar el servicio
echo ""
echo "6. Verificando conectividad desde Traefik:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    # Intentar resolver el nombre del servicio
    docker exec $TRAEFIK_CONTAINER nslookup $SERVICE_NAME 2>&1 | head -5 || echo "nslookup no disponible"
fi

# 7. Verificar configuración de Traefik dinámica
echo ""
echo "7. Verificando configuración dinámica de Traefik:"
docker exec $(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1) cat /etc/traefik/traefik.yml 2>&1 | head -20 || echo "No se pudo acceder a la configuración"

echo ""
echo "=== Verificación completada ==="






