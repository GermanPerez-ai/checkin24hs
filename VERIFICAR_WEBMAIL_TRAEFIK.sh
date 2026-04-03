#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO CONFIGURACIÓN DE WEBMAIL"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# 1. Verificar labels de Traefik
echo "1️⃣ Labels de Traefik configuradas:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>/dev/null | grep -i traefik

if [ $? -ne 0 ]; then
    echo "❌ No se encontraron labels de Traefik"
else
    echo "✅ Labels encontradas"
fi
echo ""

# 2. Verificar red de Traefik
echo "2️⃣ Red de Traefik:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Spec.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{"\n"}}{{end}}' 2>/dev/null
docker service inspect "$SERVICE_NAME" --format '{{range $net, $config := .Spec.TaskTemplate.Networks}}{{printf "Red: %s\n" $net}}{{end}}' 2>/dev/null
echo ""

# 3. Verificar logs de Traefik para webmail
echo "3️⃣ Logs de Traefik relacionados con webmail (últimas 20 líneas):"
echo "----------------------------------------"
docker service logs traefik --tail 200 2>&1 | grep -i webmail | tail -20 || echo "   No se encontraron logs recientes"
echo ""

# 4. Verificar si Traefik detecta el servicio
echo "4️⃣ Verificando si Traefik detecta el servicio:"
echo "----------------------------------------"
# Intentar acceder al dashboard de Traefik o verificar configuración
docker service logs traefik --tail 100 2>&1 | grep -iE "webmail|$DOMAIN" | tail -10 || echo "   No se encontraron referencias en logs"
echo ""

# 5. Verificar entrada HTTPS (websecure)
echo "5️⃣ Verificando si necesita configuración HTTPS:"
echo "----------------------------------------"
HTTPS_LABEL=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.routers.webmail.entrypoints"}}{{$v}}{{end}}{{end}}' 2>/dev/null)

if [ "$HTTPS_LABEL" = "web" ]; then
    echo "⚠️  Actualmente configurado para HTTP (web)"
    echo "   Para HTTPS, debería ser 'websecure'"
    echo ""
    echo "💡 ¿Quieres configurar HTTPS? Ejecuta:"
    echo "   docker service update \\"
    echo "     --label-rm traefik.http.routers.webmail.entrypoints \\"
    echo "     --label-add 'traefik.http.routers.webmail.entrypoints=websecure' \\"
    echo "     $SERVICE_NAME"
else
    echo "✅ Entrypoint: $HTTPS_LABEL"
fi
echo ""

# 6. Probar acceso HTTP y HTTPS
echo "6️⃣ Probando acceso HTTP y HTTPS:"
echo "----------------------------------------"
echo "🌐 HTTP: http://$DOMAIN/"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$DOMAIN/" 2>&1 || echo "000")
echo "   HTTP Status: $HTTP_STATUS"

echo "🌐 HTTPS: https://$DOMAIN/"
HTTPS_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" --max-time 5 "https://$DOMAIN/" 2>&1 || echo "000")
echo "   HTTPS Status: $HTTPS_STATUS"
echo ""

# 7. Verificar contenedor interno
echo "7️⃣ Verificando contenedor interno:"
echo "----------------------------------------"
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "📦 Contenedor: $WEBMAIL_CONTAINER"
    INTERNAL_HTTP=$(docker exec "$WEBMAIL_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
    echo "   HTTP interno: $INTERNAL_HTTP"
else
    echo "⚠️  No se encontró contenedor"
fi
echo ""

# 8. Verificar configuración de dominio en DNS
echo "8️⃣ Verificando DNS:"
echo "----------------------------------------"
DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1)
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "desconocida")

if [ -n "$DOMAIN_IP" ]; then
    echo "✅ DNS resuelve: $DOMAIN -> $DOMAIN_IP"
    if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
        echo "✅ IP del dominio coincide con IP del servidor"
    else
        echo "⚠️  IP del dominio ($DOMAIN_IP) no coincide con IP del servidor ($SERVER_IP)"
    fi
else
    echo "⚠️  No se pudo resolver DNS para $DOMAIN"
fi
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""

if [ "$HTTPS_STATUS" = "000" ] && [ "$HTTP_STATUS" = "000" ]; then
    echo "❌ No se puede conectar ni por HTTP ni por HTTPS"
    echo ""
    echo "Posibles causas:"
    echo "  1. Traefik aún no ha detectado los cambios (espera 1-2 minutos)"
    echo "  2. El dominio no está apuntando al servidor correcto"
    echo "  3. Traefik necesita configuración HTTPS (websecure)"
    echo ""
    echo "Soluciones:"
    echo "  1. Espera 2-3 minutos y prueba de nuevo"
    echo "  2. Verifica que el DNS esté configurado correctamente"
    echo "  3. Configura HTTPS si es necesario (ver paso 5)"
elif [ "$HTTPS_STATUS" = "504" ]; then
    echo "⚠️  HTTPS devuelve 504 Gateway Timeout"
    echo "   Traefik detecta el servicio pero no puede conectarse"
    echo "   Verifica los logs: docker service logs $SERVICE_NAME --tail 50"
elif [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS funcionando correctamente!"
elif [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ HTTP funcionando correctamente!"
    echo "   Considera configurar HTTPS para mayor seguridad"
fi
echo ""
