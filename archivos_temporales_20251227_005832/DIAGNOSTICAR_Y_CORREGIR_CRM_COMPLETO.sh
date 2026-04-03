#!/bin/bash

echo "=== Diagnóstico completo del CRM ==="

# 1. Verificar etiquetas Traefik actuales
echo ""
echo "1. Etiquetas Traefik actuales:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No hay etiquetas Traefik"

# 2. Verificar redes del servicio
echo ""
echo "2. Redes del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

# 3. Verificar red easypanel
echo ""
echo "3. Verificando red easypanel:"
docker network ls | grep easypanel
EASYPANEL_NETWORK_ID=$(docker network ls --format "{{.ID}}" --filter "name=easypanel" | head -1)
if [ ! -z "$EASYPANEL_NETWORK_ID" ]; then
    echo "ID de red easypanel: $EASYPANEL_NETWORK_ID"
else
    echo "No se encontró la red easypanel"
fi

# 4. Verificar contenedor actual
echo ""
echo "4. Contenedor actual del CRM:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    
    echo ""
    echo "5. Proceso corriendo en el contenedor:"
    docker exec $CONTAINER_ID ps aux | grep node
    
    echo ""
    echo "6. Verificando puerto 3005:"
    docker exec $CONTAINER_ID netstat -tuln 2>/dev/null | grep 3005 || docker exec $CONTAINER_ID ss -tuln 2>/dev/null | grep 3005 || echo "No se puede verificar el puerto"
    
    echo ""
    echo "7. Verificando archivo serve-crm.js:"
    docker exec $CONTAINER_ID head -10 /app/serve-crm.js
    
    echo ""
    echo "8. Verificando que crm.html existe:"
    docker exec $CONTAINER_ID ls -lh /app/crm.html
    
    echo ""
    echo "9. Probando conexión con curl (más robusto que wget):"
    docker exec $CONTAINER_ID curl -s --max-time 5 http://localhost:3005 2>&1 | head -10
    
    echo ""
    echo "10. Verificando logs del contenedor:"
    docker logs $CONTAINER_ID --tail 10 2>&1
else
    echo "No se encontró contenedor corriendo"
fi

# 5. Verificar si el servicio está en la red easypanel
echo ""
echo "11. Verificando si el servicio está en la red easypanel:"
SERVICE_NETWORKS=$(docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
if echo "$SERVICE_NETWORKS" | grep -q "$EASYPANEL_NETWORK_ID"; then
    echo "✅ El servicio está en la red easypanel"
else
    echo "⚠️  El servicio NO está en la red easypanel"
    echo "Agregando red easypanel..."
    docker service update --network-add easypanel checkin24hs_crm
fi

# 6. Configurar Traefik correctamente
echo ""
echo "12. Configurando Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm

# 7. Esperar y verificar
echo ""
echo "13. Esperando 20 segundos..."
sleep 20

# 8. Verificar etiquetas después de la actualización
echo ""
echo "14. Etiquetas Traefik después de la actualización:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 9. Verificar logs de Traefik
echo ""
echo "15. Logs de Traefik relacionados con CRM:"
docker service logs traefik --tail 50 | grep -iE "crm|checkin24hs_crm" | tail -10

# 10. Verificar nuevo contenedor
echo ""
echo "16. Verificando nuevo contenedor después del reinicio:"
NEW_CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    echo ""
    echo "17. Probando conexión en el nuevo contenedor:"
    docker exec $NEW_CONTAINER_ID curl -s --max-time 5 http://localhost:3005 2>&1 | head -10
fi

echo ""
echo "=== Diagnóstico completado ==="






