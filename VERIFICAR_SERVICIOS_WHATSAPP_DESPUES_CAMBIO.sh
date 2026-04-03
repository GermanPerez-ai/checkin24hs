#!/bin/bash
# Verificar que los servicios de WhatsApp siguen funcionando después del cambio

echo "=== VERIFICANDO SERVICIOS DE WHATSAPP ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    SUBDOMAIN="api${i}.checkin24hs.com"
    
    echo "=== $SERVICE_NAME ($SUBDOMAIN) ==="
    
    # Verificar que el servicio está corriendo
    if docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.CurrentState}}" | grep -q "Running"; then
        echo "✅ Servicio corriendo"
    else
        echo "❌ Servicio NO está corriendo"
    fi
    
    # Verificar labels de Traefik
    echo "Labels de Traefik:"
    docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | grep -E "port|server" | head -3
    
    # Verificar acceso HTTPS
    echo -n "Acceso HTTPS: "
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 (servicio responde pero ruta no existe)"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 (Bad Gateway)"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    
    echo ""
done

echo "=== RESUMEN ==="
echo "Los servicios de WhatsApp tienen configuraciones independientes del dashboard."
echo "Cambiar el puerto del dashboard NO afecta a WhatsApp."
echo ""






