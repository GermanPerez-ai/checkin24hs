#!/bin/bash
# Verificar labels aplicados y probar conexión

echo "=== VERIFICANDO LABELS APLICADOS ==="
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    echo "=== $SERVICE_NAME ==="
    docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -E "traefik|loadbalancer" | head -10
    echo ""
done

echo "=== PROBANDO CONEXIÓN A TRAVÉS DE TRAEFIK ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "Probando https://${SUBDOMAIN}/api/qr?card=${i}..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 - ¡Funciona correctamente!"
        echo "Respuesta:"
        curl -s https://${SUBDOMAIN}/api/qr?card=${i} | head -3
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 - Ruta no encontrada"
        echo "Probando ruta raíz..."
        ROOT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://${SUBDOMAIN}/ 2>&1)
        echo "Respuesta en /: HTTP $ROOT_CODE"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Bad Gateway (Traefik no puede conectar al servicio)"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "❌ Sin respuesta"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    echo ""
done

echo "=== VERIFICANDO LOGS DE TRAEFIK ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Últimos logs de Traefik relacionados con api1-4:"
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -iE "api[1-4]|whatsapp|502|404" | tail -15 || echo "   (sin logs relevantes)"
fi

echo ""
echo "✅ Verificación completada"
echo ""






