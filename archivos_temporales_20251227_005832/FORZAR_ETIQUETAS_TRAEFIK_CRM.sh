#!/bin/bash

echo "=== Forzar configuración de Traefik para CRM ==="

# 1. Ver estado actual del servicio
echo ""
echo "1. Estado actual del servicio:"
docker service inspect checkin24hs_crm --format '{{.Spec.Name}}'
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -10

# 2. Verificar si hay etiquetas Traefik
echo ""
echo "2. Verificando etiquetas Traefik existentes:"
TRAEFIK_LABELS=$(docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik)
if [ -z "$TRAEFIK_LABELS" ]; then
    echo "No hay etiquetas Traefik configuradas"
else
    echo "$TRAEFIK_LABELS"
fi

# 3. Agregar etiquetas Traefik una por una para asegurar que se agreguen
echo ""
echo "3. Agregando etiquetas Traefik una por una..."

docker service update \
  --label-add "traefik.enable=true" \
  checkin24hs_crm

sleep 3

docker service update \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  checkin24hs_crm

sleep 3

docker service update \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  checkin24hs_crm

sleep 3

docker service update \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  checkin24hs_crm

sleep 3

docker service update \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm

# 4. Verificar que se agregaron
echo ""
echo "4. Verificando etiquetas después de agregar:"
sleep 5
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 5. Verificar valores específicos
echo ""
echo "5. Valores específicos de las etiquetas:"
echo "traefik.enable: $(docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.enable"}}')"
echo "traefik.http.routers.crm.rule: $(docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.routers.crm.rule"}}')"
echo "traefik.http.services.crm.loadbalancer.server.port: $(docker service inspect checkin24hs_crm --format '{{index .Spec.TaskTemplate.ContainerSpec.Labels "traefik.http.services.crm.loadbalancer.server.port"}}')"

# 6. Reiniciar Traefik para que detecte los cambios
echo ""
echo "6. Reiniciando Traefik para que detecte los cambios..."
docker service update --force traefik

# 7. Esperar y verificar logs
echo ""
echo "7. Esperando 30 segundos..."
sleep 30

echo ""
echo "8. Logs de Traefik relacionados con CRM:"
docker service logs traefik --tail 100 | grep -iE "crm|checkin24hs_crm" | tail -20

# 9. Probar acceso
echo ""
echo "9. Probando acceso:"
curl -I http://crm.checkin24hs.com 2>&1 | head -10

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Si aún no funciona después de 1-2 minutos, verifica:"
echo "1. Que Traefik tenga acceso a Docker Swarm"
echo "2. Que el servicio esté en la red easypanel"
echo "3. Los logs completos de Traefik: docker service logs traefik --tail 200"






