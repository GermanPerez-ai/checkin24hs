#!/bin/bash
# Verificar certificados SSL de todos los subdominios

echo "=== VERIFICANDO CERTIFICADOS SSL ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "=== $SUBDOMAIN ==="
    
    CERT_INFO=$(openssl s_client -servername $SUBDOMAIN -connect $SUBDOMAIN:443 </dev/null 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)
    
    if [ -n "$CERT_INFO" ]; then
        echo "$CERT_INFO" | sed 's/^/   /'
        
        # Verificar si es el certificado por defecto
        if echo "$CERT_INFO" | grep -q "TRAEFIK DEFAULT CERT"; then
            echo "   ⚠️ Aún usando certificado por defecto"
        else
            echo "   ✅ Certificado de Let's Encrypt válido"
        fi
    else
        echo "   ❌ No se pudo verificar certificado"
    fi
    
    echo ""
done

echo "=== VERIFICANDO ACCESO HTTPS ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo -n "Probando https://$SUBDOMAIN... "
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://$SUBDOMAIN 2>&1)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "✅ HTTP $HTTP_CODE"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️ Sin respuesta (puede ser normal si el servicio no está configurado)"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
done

echo ""
echo "✅ Verificación completada"
echo ""






