#!/bin/bash

echo "=== Verificar y corregir Traefik para CRM ==="

# 1. Verificar TODAS las etiquetas del servicio
echo ""
echo "1. Todas las etiquetas del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}'

# 2. Verificar contenedor actual
echo ""
echo "2. Contenedor actual del CRM:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor ID: $CONTAINER_ID"
    
    # Obtener IP de otra manera
    echo ""
    echo "3. IP del contenedor en la red easypanel:"
    docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{println}}{{end}}' | head -1
    
    # O mejor, obtener todas las redes
    echo ""
    echo "4. Todas las redes del contenedor:"
    docker inspect $CONTAINER_ID --format '{{json .NetworkSettings.Networks}}' | python3 -m json.tool 2>/dev/null || docker inspect $CONTAINER_ID | grep -A 10 "Networks"
    
    # Obtener IP específica de easypanel
    echo ""
    echo "5. IP en la red easypanel (método alternativo):"
    docker inspect $CONTAINER_ID | grep -A 20 '"easypanel"' | grep IPAddress | head -1
    
    # Probar conexión directa
    echo ""
    echo "6. Probando conexión directa al contenedor:"
    CRM_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{println}}{{end}}' | head -1)
    if [ ! -z "$CRM_IP" ] && [ "$CRM_IP" != "" ]; then
        echo "IP encontrada: $CRM_IP"
        timeout 3 bash -c "echo > /dev/tcp/$CRM_IP/3005" 2>/dev/null && echo "✅ Puerto 3005 accesible" || echo "⚠️  Puerto 3005 no accesible"
        curl -I --max-time 3 http://$CRM_IP:3005 2>&1 | head -5
    else
        echo "No se pudo obtener la IP"
    fi
fi

# 7. Verificar si las etiquetas Traefik se agregaron
echo ""
echo "7. Verificando etiquetas Traefik específicas:"
docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.enable"}}'
docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.routers.crm.rule"}}'
docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.services.crm.loadbalancer.server.port"}}'

# 8. Si no están las etiquetas, agregarlas de nuevo
echo ""
echo "8. Verificando si necesitamos agregar etiquetas..."
TRAEFIK_ENABLE=$(docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.enable"}}')
if [ -z "$TRAEFIK_ENABLE" ] || [ "$TRAEFIK_ENABLE" != "true" ]; then
    echo "Agregando etiquetas Traefik..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.crm.entrypoints=web" \
      --label-add "traefik.http.routers.crm.entrypoints=websecure" \
      --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
      checkin24hs_crm
    
    echo "Esperando 20 segundos..."
    sleep 20
else
    echo "✅ Las etiquetas Traefik ya están configuradas"
fi

# 9. Verificar logs de Traefik
echo ""
echo "9. Logs de Traefik (últimas 50 líneas buscando CRM):"
docker service logs traefik --tail 100 | grep -iE "crm|checkin24hs_crm" | tail -20

# 10. Verificar configuración de Traefik
echo ""
echo "10. Verificando que Traefik esté en la red easypanel:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    docker inspect $TRAEFIK_CONTAINER --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{println}}{{end}}' | grep easypanel && echo "✅ Traefik está en easypanel"
fi

# 11. Probar acceso usando el nombre del servicio (Docker Swarm)
echo ""
echo "11. Probando acceso usando el nombre del servicio:"
docker run --rm --network easypanel curlimages/curl:latest curl -I --max-time 5 http://tasks.checkin24hs_crm:3005 2>&1 | head -10 || echo "No se pudo probar (puede que curl no esté disponible)"

echo ""
echo "=== Verificación completada ==="






