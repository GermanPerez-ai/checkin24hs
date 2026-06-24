#!/bin/bash
# Busca en logs de las 4 líneas WhatsApp envíos Flor y mensajes relacionados.
# Uso: bash scripts/buscar_log_flor_outbound_servidor.sh "Marisa"
#      bash scripts/buscar_log_flor_outbound_servidor.sh "profesionales de la salud"

set -euo pipefail
QUERY="${1:-Flor OUT}"
LINES="${2:-200}"

for svc in checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
  if ! docker service inspect "$svc" >/dev/null 2>&1; then continue; fi
  echo ""
  echo "========== $svc (últimas $LINES líneas, grep: $QUERY) =========="
  docker service logs "$svc" --tail "$LINES" 2>&1 | grep -iE "$QUERY|Flor OUT|mensaje antiguo|append sin timestamp|destJid.*no coincide" || echo "(sin coincidencias)"
done
