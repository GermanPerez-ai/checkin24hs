#!/bin/bash
# Verificación rápida del estado de WhatsApp
# Versión simplificada para verificación post-deploy

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"

echo "🔍 Verificación rápida: WhatsApp"
echo ""

# Verificar servicio
if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "✅ Servicio: OK"
else
    echo "❌ Servicio: NO encontrado"
    exit 1
fi

# Verificar red
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "✅ Red easypanel: OK"
else
    echo "❌ Red easypanel: FALTA"
fi

# Verificar etiquetas Traefik
CURRENT_LABELS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s\n" $k}}{{end}}' 2>/dev/null)
if echo "$CURRENT_LABELS" | grep -q "traefik.enable"; then
    echo "✅ Etiquetas Traefik: OK"
else
    echo "❌ Etiquetas Traefik: FALTAN"
fi

# Verificar endpoint
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://${DOMAIN}/api/health" 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Endpoint accesible: OK"
else
    echo "⚠️  Endpoint: HTTP $HTTP_CODE"
fi

echo ""
echo "🌐 Prueba: https://${DOMAIN}/qr"
