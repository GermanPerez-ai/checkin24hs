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
echo "   Esperando que no queden contenedores..."
for i in $(seq 1 30); do
  left=$(docker ps -aq --filter "name=${SERVICE}" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${left:-0}" == "0" ]]; then
    echo "   OK: sin contenedores ($i s)"
    break
  fi
  # Forzar stop/rm de tareas residuales
  docker ps -aq --filter "name=${SERVICE}" | xargs -r docker rm -f 2>/dev/null || true
  sleep 2
  if [[ "$i" -eq 30 ]]; then
    echo "⚠️  Aún hay contenedores; sigo igual..."
    docker ps -a --filter "name=${SERVICE}" || true
  fi
done
sleep 3

echo "🗑️ Volúmenes relacionados:"
docker volume ls | grep -iE "whatsapp|auth" || true

# Nombres típicos según deploy / EasyPanel
CANDIDATES=(
  "whatsapp${LINE}-auth"
  "checkin24hs_whatsapp${LINE}-auth"
  "${SERVICE}-auth"
)
if [[ "$LINE" == "1" ]]; then
  CANDIDATES+=("whatsapp-auth" "checkin24hs_whatsapp-auth" "checkin24hs_whatsapp_whatsapp-session")
fi
if [[ "$LINE" == "2" ]]; then
  CANDIDATES+=("checkin24hs_whatsapp_whatsapp-session-2")
fi

REMOVED=0
for vol in "${CANDIDATES[@]}"; do
  if docker volume inspect "$vol" >/dev/null 2>&1; then
    echo "   Borrando volumen: $vol"
    if docker volume rm -f "$vol" 2>/dev/null; then
      REMOVED=1
      echo "   ✅ $vol eliminado"
    else
      echo "   ⚠️  rm -f falló; intentando desmontar vía contenedores muertos..."
      docker ps -aq --filter "name=${SERVICE}" | xargs -r docker rm -f 2>/dev/null || true
      sleep 2
      if docker volume rm -f "$vol" 2>/dev/null; then
        REMOVED=1
        echo "   ✅ $vol eliminado (2º intento)"
      else
        echo "   ❌ No se pudo borrar $vol"
      fi
    fi
  fi
done

# Fallback: detectar mount real del servicio
if [[ "$REMOVED" -eq 0 ]]; then
  echo "   Inspeccionando mounts del servicio..."
  MOUNTS=$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}} {{.Target}}{{"\n"}}{{end}}' 2>/dev/null || true)
  echo "$MOUNTS"
  while read -r src tgt; do
    [[ -z "${src:-}" ]] && continue
    if echo "${tgt:-}" | grep -q "auth_info_baileys_${LINE}"; then
      echo "   Borrando volumen montado: $src → $tgt"
      if docker volume rm -f "$src" 2>/dev/null; then
        REMOVED=1
        echo "   ✅ $src eliminado"
      fi
    fi
  done <<< "$MOUNTS"
fi

if [[ "$REMOVED" -eq 0 ]]; then
  echo "❌ No se pudo borrar el volumen de auth."
  echo "   docker volume ls | grep -i whatsapp"
  echo "   docker volume rm -f whatsapp${LINE}-auth"
  exit 1
fi

echo "▶️ Escalando $SERVICE a 1..."
docker service scale "$SERVICE"=1

echo ""
echo "✅ Auth borrada. Escaneá el QR (debería pedir vinculación nueva):"
echo "   https://${HOST}/"
echo "   Dashboard → Flor IA → WhatsApp → Abrir QR Línea $LINE"
echo ""
echo "Logs:"
echo "   docker service logs -f --tail 80 $SERVICE"
echo "Buscá: 'QR Code generado' / 'not logged in, attempting registration'"
