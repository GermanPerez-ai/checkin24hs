#!/bin/bash

# Script para verificar qué servicios detecta Traefik

echo "=== Verificando detección de servicios en Traefik ==="

# 1. Ver logs recientes de Traefik (últimos 100)
echo ""
echo "1. Últimos logs de Traefik (buscando detección de servicios):"
docker service logs traefik --tail 200 2>&1 | grep -E "docker|service|router|backend" | tail -20

# 2. Verificar configuración de Traefik
echo ""
echo "2. Verificando configuración de Traefik:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo "Verificando argumentos de Traefik:"
    docker inspect $TRAEFIK_CONTAINER --format '{{range .Args}}{{.}}{{"\n"}}{{end}}' | grep -E "docker|swarm|provider"
fi

# 3. Verificar que Traefik tenga acceso al socket de Docker
echo ""
echo "3. Verificando acceso al socket de Docker:"
docker exec $(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1) ls -lh /var/run/docker.sock 2>&1 || echo "Socket no montado o no accesible"

# 4. Ver todos los servicios con etiquetas de Traefik
echo ""
echo "4. Servicios con etiquetas de Traefik:"
for service in $(docker service ls --format "{{.Name}}"); do
    LABELS=$(docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{printf "%s " $k}}{{end}}' 2>/dev/null | grep -i traefik)
    if [ ! -z "$LABELS" ]; then
        echo "  - $service: tiene etiquetas de Traefik"
        docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{if eq (index (split $k ".") 0) "traefik"}}{{printf "    %s=%s\n" $k $v}}{{end}}{{end}}' | grep -i traefik | head -5
    fi
done

# 5. Verificar específicamente el webmail
echo ""
echo "5. Verificación específica del webmail:"
docker service inspect checkin24hs_webmail --format '{{range $k, $v := .Spec.Labels}}{{if eq (index (split $k ".") 0) "traefik"}}{{printf "%s=%s\n" $k $v}}{{end}}{{end}}'

echo ""
echo "=== Verificación completada ==="






