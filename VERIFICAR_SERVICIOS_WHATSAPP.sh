#!/bin/bash
# Verificar nombres exactos de servicios de WhatsApp

echo "=== VERIFICANDO SERVICIOS DE WHATSAPP ==="
echo ""

echo "📋 Todos los servicios de Docker Swarm:"
docker service ls

echo ""
echo "📋 Servicios que contienen 'whatsapp':"
docker service ls | grep -i whatsapp

echo ""
echo "📋 Servicios que contienen 'api':"
docker service ls | grep -i api

echo ""
echo "=== DETALLES DE SERVICIOS WHATSAPP ==="
echo ""

docker service ls --format "{{.Name}}" | grep -i whatsapp | while read service; do
    echo "=== $service ==="
    echo "Labels:"
    docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -E "traefik|domain|host" || echo "  (sin labels relevantes)"
    echo ""
done






