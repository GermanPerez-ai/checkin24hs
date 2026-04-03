#!/bin/bash
# Verificar que los servicios de WhatsApp responden correctamente a través de HTTPS

echo "=== VERIFICANDO SERVICIOS WHATSAPP A TRAVÉS DE HTTPS ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "=== Verificando $SUBDOMAIN ==="
    
    # Verificar certificado SSL
    echo -n "Certificado SSL: "
    CERT_SUBJECT=$(openssl s_client -servername $SUBDOMAIN -connect $SUBDOMAIN:443 </dev/null 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
    
    if echo "$CERT_SUBJECT" | grep -q "TRAEFIK DEFAULT CERT"; then
        echo "⚠️ Certificado por defecto (no válido)"
    elif [ -n "$CERT_SUBJECT" ]; then
        echo "✅ Certificado válido"
        echo "$CERT_SUBJECT" | sed 's/^/   /'
    else
        echo "❌ No se pudo verificar"
    fi
    
    # Verificar respuesta HTTP
    echo -n "Respuesta HTTP: "
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://$SUBDOMAIN 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 (OK)"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 (No encontrado - pero el servidor responde)"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "❌ Sin respuesta (servicio no accesible)"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    
    # Verificar endpoint específico de WhatsApp
    echo -n "Endpoint /api/qr: "
    QR_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://$SUBDOMAIN/api/qr?card=$i 2>&1)
    
    if [ "$QR_RESPONSE" = "200" ]; then
        echo "✅ HTTP 200"
    elif echo "$QR_RESPONSE" | grep -q "certificate\|SSL\|TLS"; then
        echo "❌ Error de certificado SSL"
    elif [ "$QR_RESPONSE" = "000" ]; then
        echo "⚠️ Sin respuesta"
    else
        echo "⚠️ HTTP $QR_RESPONSE"
    fi
    
    echo ""
done

echo "=== VERIFICANDO CONFIGURACIÓN DE TRAEFIK ==="
echo ""

# Verificar labels de los servicios
for service in checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "=== $service ==="
    docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -E "traefik|tls|certresolver" | head -10
    echo ""
done

echo "=== VERIFICANDO LOGS DE TRAEFIK ==="
echo ""
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Últimos logs relacionados con api1-4:"
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -iE "api[1-4]|whatsapp" | tail -10 || echo "   (sin logs relevantes)"
fi

echo ""
echo "✅ Verificación completada"
echo ""






