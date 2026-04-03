#!/bin/bash
# Script post-deploy para WhatsApp
# Ejecutar después de cada deploy en EasyPanel
# Verifica y reaplica Traefik automáticamente si es necesario

echo "=========================================="
echo "🚀 POST-DEPLOY: WHATSAPP"
echo "=========================================="
echo ""

# Ejecutar el script de verificación y reaplicación
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="${SCRIPT_DIR}/VERIFICAR_Y_REAPLICAR_TRAEFIK.sh"

if [ -f "$VERIFY_SCRIPT" ]; then
    echo "📋 Ejecutando verificación automática..."
    echo ""
    bash "$VERIFY_SCRIPT"
else
    echo "⚠️  Script de verificación no encontrado: $VERIFY_SCRIPT"
    echo "   Usando método rápido..."
    echo ""
    
    # Fallback al método rápido
    SERVICE_NAME="checkin24hs_whatsapp"
    DOMAIN="whatsapp.checkin24hs.com"
    PORT="3001"
    ROUTER_NAME="whatsapp-main"
    
    docker service update \
      --network-add easypanel \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.tls=true" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}" \
      $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
    
    echo ""
    echo "✅ Configuración aplicada"
fi

echo ""
echo "=========================================="
echo "✅ POST-DEPLOY COMPLETADO"
echo "=========================================="
echo ""
echo "💡 Próximos pasos:"
echo "   1. Espera 10-30 segundos"
echo "   2. Prueba: https://whatsapp.checkin24hs.com/qr"
echo "   3. Verifica que el QR se muestre correctamente"
echo ""
