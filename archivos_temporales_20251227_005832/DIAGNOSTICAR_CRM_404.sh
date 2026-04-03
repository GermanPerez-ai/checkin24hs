#!/bin/bash

echo "=== Diagnóstico CRM 404 ==="

# 1. Verificar estado del servicio CRM
echo ""
echo "1. Estado del servicio CRM:"
docker service ps checkin24hs_crm --no-trunc | head -5

# 2. Ver logs del CRM
echo ""
echo "2. Logs del CRM (últimas 30 líneas):"
docker service logs checkin24hs_crm --tail 30

# 3. Verificar contenedor corriendo
echo ""
echo "3. Contenedor del CRM:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor ID: $CONTAINER_ID"
    echo ""
    echo "4. Proceso corriendo en el contenedor:"
    docker exec $CONTAINER_ID ps aux | grep node
    echo ""
    echo "5. Archivos en /app:"
    docker exec $CONTAINER_ID ls -lh /app/serve-crm.js /app/crm.html 2>&1
    echo ""
    echo "6. Probar conexión interna (puerto 3005):"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3005 2>&1 | head -10
else
    echo "No se encontró contenedor corriendo"
fi

# 4. Verificar etiquetas Traefik del servicio CRM
echo ""
echo "7. Etiquetas Traefik del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.ContainerSpec.Labels}}{{.}}{{println}}{{end}}' | grep -i traefik

# 5. Verificar configuración de Traefik
echo ""
echo "8. Verificando si Traefik detecta el servicio CRM:"
docker service logs traefik --tail 50 | grep -i crm | tail -10

# 6. Verificar puerto del servicio
echo ""
echo "9. Puertos del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}'

# 7. Verificar red de Traefik
echo ""
echo "10. Redes del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

echo ""
echo "=== Diagnóstico completado ==="






