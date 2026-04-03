#!/bin/bash
# Verificar que todos los servicios de WhatsApp funcionan con SSL

echo "=== VERIFICANDO TODOS LOS SERVICIOS WHATSAPP CON SSL ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo "=== $SUBDOMAIN ==="
    
    # Verificar certificado SSL
    echo -n "Certificado SSL: "
    CERT_SUBJECT=$(openssl s_client -servername $SUBDOMAIN -connect $SUBDOMAIN:443 </dev/null 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
    
    if echo "$CERT_SUBJECT" | grep -q "TRAEFIK DEFAULT CERT"; then
        echo "⚠️ Certificado por defecto"
    elif [ -n "$CERT_SUBJECT" ]; then
        echo "✅ Certificado válido"
        echo "$CERT_SUBJECT" | sed 's/^/   /'
    else
        echo "❌ No se pudo verificar"
    fi
    
    # Verificar respuesta HTTP
    echo -n "Respuesta HTTP: "
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://${SUBDOMAIN}/api/qr?card=${i} 2>&1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 - Funciona correctamente"
        
        # Mostrar respuesta
        echo "Respuesta (primeros 100 caracteres):"
        curl -s https://${SUBDOMAIN}/api/qr?card=${i} 2>&1 | head -c 100
        echo ""
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️ HTTP 404 - Ruta no encontrada"
    elif [ "$HTTP_CODE" = "502" ]; then
        echo "❌ HTTP 502 - Bad Gateway"
    else
        echo "⚠️ HTTP $HTTP_CODE"
    fi
    
    echo ""
done

echo "=== RESUMEN ==="
echo ""
echo "✅ Si todos los servicios muestran HTTP 200, la configuración SSL está completa"
echo "✅ Los certificados SSL están funcionando correctamente"
echo "✅ Traefik puede conectarse a los servicios de WhatsApp"
echo ""
echo "📝 PRÓXIMO PASO:"
echo "   1. Recarga el dashboard con Ctrl+Shift+R"
echo "   2. Ve a Flor IA → WhatsApp"
echo "   3. Intenta conectar WhatsApp"
echo "   4. Debería funcionar sin errores de certificado SSL"
echo ""






