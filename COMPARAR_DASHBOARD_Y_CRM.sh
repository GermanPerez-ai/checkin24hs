#!/bin/bash

echo "=== Comparar configuración Dashboard vs CRM ==="

# 1. Ver etiquetas del contenedor Dashboard
echo ""
echo "1. Etiquetas del contenedor Dashboard:"
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Contenedor Dashboard: $DASHBOARD_CONTAINER"
    docker inspect $DASHBOARD_CONTAINER --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik
    echo ""
    echo "Todas las etiquetas del Dashboard:"
    docker inspect $DASHBOARD_CONTAINER --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -20
fi

# 2. Ver etiquetas del contenedor CRM
echo ""
echo "2. Etiquetas del contenedor CRM:"
CRM_CONTAINER=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CRM_CONTAINER" ]; then
    echo "Contenedor CRM: $CRM_CONTAINER"
    docker inspect $CRM_CONTAINER --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik
    echo ""
    echo "Todas las etiquetas del CRM:"
    docker inspect $CRM_CONTAINER --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -20
fi

# 3. Ver etiquetas del servicio Dashboard
echo ""
echo "3. Etiquetas del servicio Dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -20

# 4. Ver etiquetas del servicio CRM
echo ""
echo "4. Etiquetas del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -20

# 5. Ver configuración completa del servicio Dashboard
echo ""
echo "5. Configuración completa del servicio Dashboard (solo labels):"
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | python3 -m json.tool 2>/dev/null | head -30 || docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}'

# 6. Ver configuración completa del servicio CRM
echo ""
echo "6. Configuración completa del servicio CRM (solo labels):"
docker service inspect checkin24hs_crm --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | python3 -m json.tool 2>/dev/null | head -30 || docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}'

echo ""
echo "=== Comparación completada ==="


















