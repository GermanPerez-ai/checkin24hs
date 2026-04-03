#!/bin/bash
# Limpiar sesión WhatsApp (auth) para resolver Bad MAC, No matching sessions, conflict 440
# Ejecutar en el servidor donde corre Docker Swarm

set -e
SERVICE="checkin24hs_whatsapp"
VOLUME="${SERVICE}-auth"

echo "🛑 Deteniendo servicio WhatsApp..."
docker service scale "$SERVICE"=0
sleep 5

echo "🗑️ Eliminando volumen de auth ($VOLUME)..."
docker volume rm "$VOLUME" 2>/dev/null || {
    echo "   (Volumen no existe o ya fue eliminado)"
}

echo "▶️ Iniciando servicio (pedirá QR nuevo)..."
docker service scale "$SERVICE"=1

echo ""
echo "✅ Listo. Entrá a https://whatsapp.checkin24hs.com/qr para escanear el QR."
echo "   Logs: docker service logs -f $SERVICE"
