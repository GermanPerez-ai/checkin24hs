#!/bin/bash

echo "=== Verificar si Traefik detecta el CRM ==="

# 1. Verificar etiquetas Traefik
echo ""
echo "1. Etiquetas Traefik configuradas:"
docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.enable"}}'
docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.routers.crm.rule"}}'
docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.services.crm.loadbalancer.server.port"}}'

# 2. Ver todas las etiquetas
echo ""
echo "2. Todas las etiquetas del servicio:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 3. Ver logs de Traefik
echo ""
echo "3. Logs de Traefik (buscando CRM):"
docker service logs traefik --tail 100 | grep -iE "crm|checkin24hs_crm" | tail -20

# 4. Verificar configuración de Traefik (dashboard API)
echo ""
echo "4. Verificando configuración de Traefik a través de la API:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Intentando acceder al dashboard de Traefik..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i crm || echo "No se encontró configuración de CRM en Traefik"
fi

# 5. Verificar que el servicio esté en la red correcta
echo ""
echo "5. Verificando redes del servicio:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

# 6. Probar acceso desde Traefik al servicio CRM
echo ""
echo "6. Probando acceso desde Traefik al CRM:"
CRM_IP="10.0.1.119"
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://${CRM_IP}:3005 2>&1 | head -10 || echo "No se pudo acceder desde Traefik"
fi

# 7. Verificar configuración de Traefik (archivos)
echo ""
echo "7. Verificando configuración de Traefik:"
docker service inspect traefik --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -iE "docker|swarm|providers" | head -10

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si las etiquetas Traefik están configuradas pero Traefik no las detecta:"
echo "1. Espera 1-2 minutos más para que Traefik propague los cambios"
echo "2. Reinicia Traefik si es necesario: docker service update --force traefik"
echo "3. Verifica que Traefik tenga acceso a Docker Swarm: docker service inspect traefik"






