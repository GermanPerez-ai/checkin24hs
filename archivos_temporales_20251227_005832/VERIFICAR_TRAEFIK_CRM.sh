#!/bin/bash

echo "=== Verificar configuración Traefik para CRM ==="

# 1. Verificar etiquetas Traefik
echo ""
echo "1. Etiquetas Traefik del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 2. Verificar si Traefik detecta el servicio
echo ""
echo "2. Logs de Traefik relacionados con CRM:"
docker service logs traefik --tail 100 | grep -iE "crm|checkin24hs_crm" | tail -20

# 3. Verificar red del servicio
echo ""
echo "3. Redes del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

# 4. Verificar contenedor actual
echo ""
echo "4. Contenedor actual del CRM:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo ""
    echo "5. IP del contenedor en la red easypanel:"
    docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{range $value}}{{.IPAddress}}{{end}}{{println}}{{end}}' | grep easypanel
    
    echo ""
    echo "6. Probando conexión interna:"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3005 2>&1 | head -10
fi

# 5. Verificar configuración de Traefik
echo ""
echo "7. Verificando configuración de Traefik:"
docker service inspect traefik --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -iE "docker|swarm" | head -5

# 6. Probar acceso desde el servidor
echo ""
echo "8. Probando acceso desde el servidor:"
curl -I http://localhost:3005 2>&1 | head -10

# 7. Verificar si Traefik puede alcanzar el servicio
echo ""
echo "9. Verificando si Traefik puede alcanzar el servicio:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    # Intentar hacer curl desde Traefik al servicio CRM
    CRM_IP=$(docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{range $value}}{{.IPAddress}}{{end}}{{println}}{{end}}' | grep easypanel | awk '{print $2}')
    if [ ! -z "$CRM_IP" ]; then
        echo "IP del CRM: $CRM_IP"
        docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://${CRM_IP}:3005 2>&1 | head -5
    fi
fi

echo ""
echo "=== Verificación completada ==="






