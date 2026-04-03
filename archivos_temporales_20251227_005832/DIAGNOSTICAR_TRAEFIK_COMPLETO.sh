#!/bin/bash

echo "=== Diagnóstico completo de Traefik ==="

# 1. Verificar etiquetas del CRM
echo ""
echo "1. Etiquetas Traefik del CRM:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 2. Verificar etiquetas del Dashboard (que sí funciona)
echo ""
echo "2. Etiquetas Traefik del Dashboard (para comparar):"
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 3. Verificar configuración de Traefik
echo ""
echo "3. Configuración de Traefik:"
docker service inspect traefik --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -iE "docker|swarm|providers" | head -10

# 4. Ver logs completos de Traefik (últimas 100 líneas)
echo ""
echo "4. Logs completos de Traefik (últimas 100 líneas):"
docker service logs traefik --tail 100

# 5. Verificar si Traefik puede ver los servicios
echo ""
echo "5. Verificando servicios detectados por Traefik:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "Intentando acceder a la API de Traefik..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | head -50 || echo "No se puede acceder a la API de Traefik"
fi

# 6. Verificar redes de ambos servicios
echo ""
echo "6. Redes del CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

echo ""
echo "7. Redes del Dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

# 7. Verificar contenedores actuales
echo ""
echo "8. Contenedores actuales:"
echo "CRM:"
docker ps --filter "name=crm" --format "{{.ID}} {{.Names}}"
echo ""
echo "Dashboard:"
docker ps --filter "name=dashboard" --format "{{.ID}} {{.Names}}"
echo ""
echo "Traefik:"
docker ps --filter "name=traefik" --format "{{.ID}} {{.Names}}"

# 8. Comparar configuración completa
echo ""
echo "9. Comparando configuración completa del CRM vs Dashboard:"
echo ""
echo "=== CRM ==="
docker service inspect checkin24hs_crm --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | python3 -m json.tool 2>/dev/null | grep -i traefik || docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -20

echo ""
echo "=== Dashboard ==="
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | python3 -m json.tool 2>/dev/null | grep -i traefik || docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | head -20

echo ""
echo "=== Diagnóstico completado ==="






