#!/bin/bash
# Verificar si el endpoint /api/status existe y responde correctamente

echo "=== VERIFICANDO ENDPOINT /api/status EN SERVICIOS WHATSAPP ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    PORT=$((3000 + i))
    
    echo "=== Verificando $SUBDOMAIN (puerto interno $PORT) ==="
    
    # Probar HTTPS
    echo -n "HTTPS /api/status?card=${i}: "
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://${SUBDOMAIN}/api/status?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200"
        echo "Respuesta:"
        curl -s https://${SUBDOMAIN}/api/status?card=${i} 2>&1 | head -c 200
        echo ""
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "❌ HTTP 404 - Endpoint no encontrado"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Bad Gateway (Traefik no puede alcanzar el servicio)"
    elif [ "$HTTP_CODE" = "504" ]; then
        echo "❌ HTTP 504 - Gateway Timeout"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️ HTTP 000 - No se pudo conectar"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    
    # Probar desde dentro del contenedor directamente
    SERVICE_NAME="checkin24hs_whatsapp"
    if [ $i -gt 1 ]; then
        SERVICE_NAME="${SERVICE_NAME}${i}"
    fi
    
    CONTAINER=$(docker service ps $SERVICE_NAME --format "{{.Name}}" --filter "desired-state=running" | head -n 1)
    if [ -n "$CONTAINER" ]; then
        echo -n "Desde contenedor $CONTAINER (localhost:$PORT/api/status?card=${i}): "
        CONTAINER_RESPONSE=$(docker exec $CONTAINER curl -s http://localhost:${PORT}/api/status?card=${i} 2>&1)
        if [ $? -eq 0 ] && [ -n "$CONTAINER_RESPONSE" ]; then
            echo "✅ Responde"
            echo "Respuesta: $CONTAINER_RESPONSE" | head -c 200
            echo ""
        else
            echo "❌ No responde o error"
        fi
    else
        echo "⚠️ No se encontró contenedor corriendo para $SERVICE_NAME"
    fi
    
    echo ""
done

echo "=== RESUMEN ==="
echo "Si todos los endpoints devuelven 404, el servicio de WhatsApp no tiene configurado el endpoint /api/status"
echo "Si devuelven 502/504, hay un problema de conectividad entre Traefik y el servicio"
echo ""






