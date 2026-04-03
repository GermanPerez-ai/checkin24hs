#!/bin/bash

echo "=========================================="
echo "🔒 CONFIGURANDO HTTPS PARA WEBMAIL"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ ERROR: Servicio $SERVICE_NAME no encontrado"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Verificar labels actuales
echo "📋 Labels actuales:"
docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq (substr $k 0 7) "traefik"}}{{printf "  %s=%s\n" $k $v}}{{end}}{{end}}' 2>/dev/null
echo ""

# Configurar HTTPS
echo "🔒 Configurando HTTPS (websecure)..."
echo "----------------------------------------"

# Actualizar entrypoint a websecure
docker service update \
  --label-rm "traefik.http.routers.webmail.entrypoints" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  $SERVICE_NAME 2>&1 | grep -v "verify:"

echo ""
echo "✅ HTTPS configurado"
echo ""

# Esperar a que se apliquen los cambios
echo "⏳ Esperando 20 segundos para que se apliquen los cambios..."
sleep 20
echo "✅ Cambios aplicados"
echo ""

# Verificar configuración
echo "📋 Labels actualizadas:"
docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq (substr $k 0 7) "traefik"}}{{printf "  ✅ %s=%s\n" $k $v}}{{end}}{{end}}' 2>/dev/null
echo ""

# Probar acceso
echo "🌐 Probando acceso HTTPS:"
HTTPS_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN/" 2>&1 || echo "000")

if [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS funcionando correctamente!"
elif [ "$HTTPS_STATUS" = "504" ]; then
    echo "⚠️  HTTPS devuelve 504 - Espera 1-2 minutos más"
elif [ "$HTTPS_STATUS" = "000" ]; then
    echo "⚠️  No se pudo conectar - Verifica DNS y espera 2-3 minutos"
else
    echo "⚠️  HTTPS Status: $HTTPS_STATUS"
fi
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "💡 Próximos pasos:"
echo "   1. Espera 1-2 minutos para que Traefik detecte los cambios"
echo "   2. Prueba acceder a: https://$DOMAIN/"
echo "   3. Si sigue dando error, ejecuta: ./VERIFICAR_WEBMAIL_TRAEFIK.sh"
echo ""
