#!/bin/bash
# Limpia auth Baileys de una línea WhatsApp (Bad MAC / Esperando mensaje / sesión corrupta).
# Uso: cd /root/checkin24hs && bash scripts/limpiar_sesion_whatsapp_linea.sh <1|2|3|4>
#
# Después: Dashboard → Flor IA → WhatsApp → Abrir QR Línea N

set -euo pipefail

LINE="${1:-}"
if [[ ! "$LINE" =~ ^[1-4]$ ]]; then
  echo "Uso: bash scripts/limpiar_sesion_whatsapp_linea.sh <1|2|3|4>"
  exit 1
fi

if [[ "$LINE" == "1" ]]; then
  SERVICE="checkin24hs_whatsapp"
  HOST="whatsapp.checkin24hs.com"
else
  SERVICE="checkin24hs_whatsapp${LINE}"
  HOST="whatsapp${LINE}.checkin24hs.com"
fi

echo "=== Limpiar sesión WhatsApp Línea $LINE ($SERVICE) ==="

if ! docker service inspect "$SERVICE" >/dev/null 2>&1; then
  echo "❌ Servicio $SERVICE no existe"
  exit 1
fi

echo "🛑 Escalando $SERVICE a 0..."
docker service scale "$SERVICE"=0
sleep 8

echo "🗑️ Buscando volúmenes de auth..."
docker volume ls | grep -iE "whatsapp|auth" || true

# Nombres típicos según deploy / EasyPanel
CANDIDATES=(
  "whatsapp${LINE}-auth"
  "checkin24hs_whatsapp${LINE}-auth"
  "${SERVICE}-auth"
)
if [[ "$LINE" == "1" ]]; then
  CANDIDATES+=("whatsapp-auth" "checkin24hs_whatsapp-auth")
fi

REMOVED=0
for vol in "${CANDIDATES[@]}"; do
  if docker volume inspect "$vol" >/dev/null 2>&1; then
    echo "   Borrando volumen: $vol"
    if docker volume rm "$vol" 2>/dev/null; then
      REMOVED=1
      echo "   ✅ $vol eliminado"
    else
      echo "   ⚠️  No se pudo borrar $vol (¿en uso?). Probá:"
      echo "      docker ps -a | grep whatsapp${LINE}"
      echo "      docker volume rm -f $vol"
    fi
  fi
done

if [[ "$REMOVED" -eq 0 ]]; then
  echo "⚠️  No se encontró volumen con nombre estándar."
  echo "   Listá y borrá a mano el que monte auth_info_baileys_${LINE}:"
  echo "   docker volume ls | grep -i whatsapp"
  echo "   docker service inspect $SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}'"
fi

echo "▶️ Escalando $SERVICE a 1..."
docker service scale "$SERVICE"=1
sleep 5

echo ""
echo "✅ Listo. Escaneá el QR:"
echo "   https://${HOST}/"
echo "   o Dashboard → Flor IA → WhatsApp → Abrir QR Línea $LINE"
echo ""
echo "Logs en vivo:"
echo "   docker service logs -f --tail 80 $SERVICE"
