#!/bin/bash

echo "=== Verificar y corregir configuración de Traefik para Docker Swarm ==="

# 1. Verificar configuración actual de Traefik
echo ""
echo "1. Configuración actual de Traefik:"
docker service inspect traefik --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -iE "docker|swarm|providers"

# 2. Ver argumentos/comando de Traefik
echo ""
echo "2. Comando/argumentos de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{println}}{{end}}'

# 3. Ver variables de entorno
echo ""
echo "3. Variables de entorno de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{println}}{{end}}' | grep -iE "docker|swarm|providers"

# 4. Verificar si Traefik tiene acceso al socket de Docker
echo ""
echo "4. Verificando acceso al socket de Docker:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker inspect $TRAEFIK_CONTAINER --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}' | grep -i docker
fi

# 5. Verificar cómo está configurado el Dashboard (que funciona)
echo ""
echo "5. Verificando cómo está configurado el Dashboard:"
docker service inspect checkin24hs_dashboard --format '{{json .Spec}}' | python3 -m json.tool 2>/dev/null | head -50 || docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -30

# 6. Verificar si hay un archivo de configuración de Traefik
echo ""
echo "6. Buscando archivos de configuración de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'

# 7. Ver logs de Traefik para entender cómo detecta servicios
echo ""
echo "7. Logs de Traefik relacionados con detección de servicios:"
docker service logs traefik --tail 200 | grep -iE "docker|swarm|provider|service|container" | tail -30

# 8. Verificar si el problema es que Traefik necesita estar en modo Swarm
echo ""
echo "8. Verificando si Traefik está en modo Swarm:"
docker service logs traefik --tail 50 | grep -iE "swarm|mode" | tail -10

echo ""
echo "=== Diagnóstico completado ==="
echo ""
echo "Si Traefik no está configurado para Docker Swarm, necesitamos:"
echo "1. Asegurarnos de que Traefik tenga acceso al socket de Docker Swarm"
echo "2. Configurar Traefik para usar el provider de Docker Swarm"
echo "3. O usar etiquetas en los contenedores individuales en lugar de servicios"






