#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
echo "=== DIAGNÓSTICO ==="
echo "Labels:"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -v "^$" || echo "(ninguna)"
echo ""
echo "Red:"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{"\n"}}{{end}}'
echo ""
echo "Traefik labels:"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik || echo "NO HAY LABELS DE TRAEFIK"
