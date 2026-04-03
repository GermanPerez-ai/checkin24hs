#!/bin/bash
# Verificar que SSL está configurado correctamente después de configurar en EasyPanel

echo "=== VERIFICACIÓN DE CONFIGURACIÓN SSL ==="
echo ""

# Verificar servicios de WhatsApp
declare -A SERVICES=(
    ["1"]="checkin24hs_whatsapp"
    ["2"]="checkin24hs_whatsapp2"
    ["3"]="checkin24hs_whatsapp3"
    ["4"]="checkin24hs_whatsapp4"
)

echo "📋 Verificando labels SSL en servicios de WhatsApp..."
echo ""

for i in 1 2 3 4; do
    SERVICE_NAME="${SERVICES[$i]}"
    SUBDOMAIN="api${i}.checkin24hs.com"
    
    echo "=== $SERVICE_NAME ($SUBDOMAIN) ==="
    
    # Verificar que el servicio existe
    if ! docker service ls | grep -q "^${SERVICE_NAME} "; then
        echo "   ⚠️ Servicio no encontrado"
        echo ""
        continue
    fi
    
    # Obtener labels de Traefik
    LABELS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik)
    
    # Verificar labels importantes
    HAS_ENABLE=$(echo "$LABELS" | grep -q "traefik.enable=true" && echo "✅" || echo "❌")
    HAS_ROUTER=$(echo "$LABELS" | grep -q "traefik.http.routers" && echo "✅" || echo "❌")
    HAS_SSL=$(echo "$LABELS" | grep -q "tls\|websecure\|letsencrypt" && echo "✅" || echo "❌")
    
    echo "   Traefik habilitado: $HAS_ENABLE"
    echo "   Router configurado: $HAS_ROUTER"
    echo "   SSL configurado: $HAS_SSL"
    
    if [ "$HAS_SSL" = "✅" ]; then
        echo "   Labels SSL encontrados:"
        echo "$LABELS" | grep -E "tls|websecure|letsencrypt" | sed 's/^/      /'
    fi
    
    echo ""
done

# Verificar Let's Encrypt en Traefik
echo "=== VERIFICANDO LET'S ENCRYPT EN TRAEFIK ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Contenedor de Traefik: $TRAEFIK_CONTAINER"
    
    # Verificar logs de Let's Encrypt
    echo ""
    echo "📋 Últimos logs relacionados con Let's Encrypt:"
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -i "letsencrypt\|acme\|certificate" | tail -10 || echo "   No se encontraron logs de Let's Encrypt"
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi

echo ""
echo "=== VERIFICANDO CERTIFICADOS SSL ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo -n "Verificando $SUBDOMAIN... "
    
    # Verificar certificado SSL
    CERT_INFO=$(echo | openssl s_client -servername $SUBDOMAIN -connect $SUBDOMAIN:443 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null)
    
    if [ -n "$CERT_INFO" ]; then
        echo "✅ Certificado SSL válido"
        echo "$CERT_INFO" | sed 's/^/   /'
    else
        echo "❌ No se pudo verificar certificado SSL"
        echo "   Esto puede ser normal si el certificado aún no se ha generado"
    fi
    echo ""
done

# Verificar acceso HTTPS
echo "=== VERIFICANDO ACCESO HTTPS ==="
echo ""

for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo -n "Probando https://$SUBDOMAIN... "
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://$SUBDOMAIN 2>&1)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "✅ HTTP $HTTP_CODE"
    elif echo "$HTTP_CODE" | grep -q "certificate\|SSL\|TLS"; then
        echo "⚠️ Error de certificado SSL"
    else
        echo "⚠️ HTTP $HTTP_CODE (puede ser normal si el servicio no responde)"
    fi
done

echo ""
echo "=== RESUMEN ==="
echo ""
echo "Si ves ✅ en SSL configurado y certificados válidos, la configuración está correcta"
echo "Si ves ❌, necesitas configurar SSL en EasyPanel siguiendo la guía"
echo ""
echo "Para más detalles, consulta: GUIA_SSL_EASYPANEL.md"
echo ""

