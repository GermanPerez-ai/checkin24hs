#!/bin/bash
# Verificar si el servicio usa volúmenes montados que podrían sobrescribir cambios

SERVICE_NAME="checkin24hs_cotizador"

echo "Verificando configuración del servicio $SERVICE_NAME..."
echo ""

echo "1. Volúmenes montados:"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>/dev/null

echo ""
echo "2. Configuración completa del servicio:"
docker service inspect "$SERVICE_NAME" --pretty | grep -A 20 "Mounts" || echo "   (sin montajes)"

echo ""
echo "3. Si hay volúmenes montados, los cambios en el contenedor se perderán al reiniciar"
echo "   Necesitarías actualizar los archivos en la ruta del volumen en el servidor"
