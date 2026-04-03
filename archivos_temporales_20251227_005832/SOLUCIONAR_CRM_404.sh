#!/bin/bash

echo "=== Solucionar CRM 404 ==="

# 1. Verificar estado actual del servicio CRM
echo ""
echo "1. Estado del servicio CRM:"
docker service ps checkin24hs_crm --no-trunc | head -3

# 2. Obtener información del servicio
echo ""
echo "2. Información del servicio CRM:"
SERVICE_NAME="checkin24hs_crm"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)

if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor encontrado: $CONTAINER_ID"
    
    # Obtener IP del contenedor en la red easypanel
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
    echo "IP del contenedor: $CONTAINER_IP"
    
    # Verificar en qué red está
    echo ""
    echo "3. Redes del contenedor:"
    docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{println}}{{end}}'
    
    # Probar conexión interna
    echo ""
    echo "4. Probando conexión interna (puerto 3005):"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3005 2>&1 | head -5
else
    echo "No se encontró contenedor corriendo"
    exit 1
fi

# 3. Verificar etiquetas Traefik actuales
echo ""
echo "5. Etiquetas Traefik actuales:"
docker service inspect $SERVICE_NAME --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 4. Obtener nombre del servicio para Traefik
SERVICE_NAME_TRAEFIK="checkin24hs_crm"
TASK_NAME=$(docker service ps $SERVICE_NAME --format "{{.Name}}" | head -1 | cut -d'.' -f1-2)

# 5. Configurar Traefik para el CRM
echo ""
echo "6. Configurando Traefik para el CRM..."

# Obtener IP del contenedor en la red easypanel
if [ -z "$CONTAINER_IP" ]; then
    # Si no tenemos IP, usar el nombre del servicio
    BACKEND_URL="http://tasks.${SERVICE_NAME_TRAEFIK}:3005"
else
    BACKEND_URL="http://${CONTAINER_IP}:3005"
fi

echo "Backend URL: $BACKEND_URL"

# Agregar/actualizar etiquetas Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  --network-add easypanel \
  $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik agregadas"
else
    echo "⚠️  Error al agregar etiquetas. Intentando método alternativo..."
    
    # Método alternativo: usar tasks.nombre_servicio
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.crm.entrypoints=web" \
      --label-add "traefik.http.routers.crm.entrypoints=websecure" \
      --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
      $SERVICE_NAME
fi

# 6. Esperar a que Traefik detecte los cambios
echo ""
echo "7. Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

# 7. Verificar logs de Traefik
echo ""
echo "8. Logs de Traefik relacionados con CRM:"
docker service logs traefik --tail 50 | grep -i crm | tail -10

# 8. Probar acceso
echo ""
echo "9. Probando acceso al CRM:"
curl -I http://crm.checkin24hs.com 2>&1 | head -10

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Si aún no funciona, verifica:"
echo "1. Que el DNS de crm.checkin24hs.com apunte a la IP del servidor"
echo "2. Que el servicio CRM esté en la red 'easypanel'"
echo "3. Que el puerto 3005 esté accesible desde Traefik"






