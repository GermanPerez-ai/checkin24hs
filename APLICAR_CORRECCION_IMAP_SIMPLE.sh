#!/bin/bash

echo "=========================================="
echo "🔧 CORRECCIÓN RÁPIDA IMAP WEBMAIL"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"

# Verificar que el servicio existe
if ! docker service inspect "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "❌ Error: El servicio '$SERVICE_NAME' no existe"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""
echo "📋 Esta corrección actualizará:"
echo "   - ROUNDCUBEMAIL_DEFAULT_HOST: mail.checkin24hs.com"
echo "   - ROUNDCUBEMAIL_DEFAULT_HOST_SSL: true"
echo "   - ROUNDCUBEMAIL_SMTP_SERVER: mail.checkin24hs.com"
echo ""
echo "⚠️  NOTA: Este script actualizará SOLO estas 3 variables."
echo "   Las demás variables de entorno se mantendrán."
echo ""

read -p "¿Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo "❌ Operación cancelada"
    exit 0
fi

echo ""
echo "🔄 Aplicando corrección..."

# Actualizar el servicio con las variables correctas
# Nota: docker service update --env-add agrega o actualiza la variable
docker service update \
    --env-add "ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com" \
    --env-add "ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true" \
    --env-add "ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com" \
    "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Corrección aplicada exitosamente"
    echo ""
    echo "⏳ Esperando 15 segundos para que el servicio se reinicie..."
    sleep 15
    
    echo ""
    echo "📊 Verificando nueva configuración:"
    echo "----------------------------------------"
    docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' 2>/dev/null | grep -iE "ROUNDCUBEMAIL_DEFAULT_HOST|ROUNDCUBEMAIL_DEFAULT_HOST_SSL|ROUNDCUBEMAIL_SMTP_SERVER" | sort
    
    echo ""
    echo "=========================================="
    echo "✅ CORRECCIÓN COMPLETADA"
    echo "=========================================="
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Espera 30 segundos más"
    echo "   2. Intenta iniciar sesión en https://webmail.checkin24hs.com"
    echo "   3. Si hay problemas, verifica los logs:"
    echo "      docker service logs $SERVICE_NAME --tail 50"
    echo ""
else
    echo ""
    echo "❌ Error al aplicar la corrección"
    echo "   Intenta hacerlo manualmente en EasyPanel"
    echo ""
fi
