#!/bin/bash

echo "=== Solución directa para CRM en Traefik ==="

# 1. Verificar que el servicio CRM está corriendo
echo ""
echo "1. Estado del servicio CRM:"
docker service ps checkin24hs_crm --no-trunc | head -3

# 2. Obtener información del servicio
echo ""
echo "2. Información del servicio CRM:"
SERVICE_NAME="checkin24hs_crm"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
echo "Contenedor: $CONTAINER_ID"

# 3. Verificar que el servicio está en la red easypanel
echo ""
echo "3. Verificando red easypanel:"
docker network inspect easypanel --format '{{.Name}}' 2>/dev/null && echo "Red easypanel existe"

# 4. Agregar etiquetas Traefik usando el nombre del servicio como backend
echo ""
echo "4. Configurando Traefik con el nombre del servicio como backend..."

# Primero, eliminar cualquier etiqueta Traefik existente
docker service update \
  --label-rm "traefik.enable" \
  --label-rm "traefik.http.routers.crm.rule" \
  --label-rm "traefik.http.routers.crm.entrypoints" \
  --label-rm "traefik.http.services.crm.loadbalancer.server.port" \
  checkin24hs_crm 2>/dev/null

sleep 5

# Agregar etiquetas Traefik usando tasks.nombre_servicio como backend
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  --label-add "traefik.docker.network=easypanel" \
  checkin24hs_crm

# 5. Verificar que se agregaron
echo ""
echo "5. Esperando 10 segundos..."
sleep 10

echo ""
echo "6. Verificando etiquetas:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 6. Reiniciar Traefik para que detecte los cambios
echo ""
echo "7. Reiniciando Traefik..."
docker service update --force traefik

# 7. Esperar y verificar
echo ""
echo "8. Esperando 30 segundos para que Traefik se reinicie y detecte los cambios..."
sleep 30

# 8. Probar acceso
echo ""
echo "9. Probando acceso:"
curl -I http://crm.checkin24hs.com 2>&1 | head -10

# 9. Ver logs de Traefik
echo ""
echo "10. Logs de Traefik (últimas 20 líneas):"
docker service logs traefik --tail 20

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Si aún no funciona, puede ser que necesites configurar las etiquetas directamente en EasyPanel"
echo "o que Traefik necesite más tiempo para detectar los cambios."






