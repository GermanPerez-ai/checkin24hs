#!/bin/bash

# Script para verificar y corregir la configuración de Traefik para webmail

SERVICE_NAME="checkin24hs_webmail"

echo "=== Verificando configuración de Traefik para webmail ==="

# 1. Ver etiquetas de Traefik
echo ""
echo "1. Etiquetas de Traefik en el servicio webmail:"
docker service inspect $SERVICE_NAME --format '{{json .Spec.Labels}}' | jq '.' 2>/dev/null || docker service inspect $SERVICE_NAME --format '{{json .Spec.Labels}}'

# 2. Verificar si tiene configuración de Traefik
echo ""
echo "2. Buscando etiquetas de Traefik específicas:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

# 3. Verificar red del servicio
echo ""
echo "3. Redes del servicio webmail:"
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# 4. Verificar red de Traefik
echo ""
echo "4. Redes de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# 5. Verificar si están en la misma red
echo ""
echo "5. Verificando si están en la misma red:"
WEBMAIL_NET=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | head -1)
TRAEFIK_NET=$(docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | head -1)

if [ "$WEBMAIL_NET" = "$TRAEFIK_NET" ]; then
    echo "✅ Ambos servicios están en la misma red: $WEBMAIL_NET"
else
    echo "❌ Están en redes diferentes:"
    echo "   Webmail: $WEBMAIL_NET"
    echo "   Traefik: $TRAEFIK_NET"
fi

# 6. Ver logs de Traefik relacionados con webmail
echo ""
echo "6. Logs de Traefik relacionados con webmail (últimas 20 líneas):"
docker service logs traefik --tail 100 2>&1 | grep -i webmail | tail -20 || echo "No se encontraron referencias a webmail"

echo ""
echo "=== Verificación completada ==="






