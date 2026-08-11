#!/usr/bin/env bash
# Descubre cómo llegar al servicio WhatsApp desde el host y prueba el monitor.
# Uso: bash scripts/site-monitor/discover-wa-url.sh 54911XXXXXXXX
set -euo pipefail

PHONE="${1:-}"
if [[ -z "$PHONE" || "$PHONE" == *"XXX"* ]]; then
  echo "Uso: bash scripts/site-monitor/discover-wa-url.sh 54911TU_NUMERO"
  echo "Ejemplo: bash scripts/site-monitor/discover-wa-url.sh 5491112345678"
  exit 1
fi

PHONE="$(echo "$PHONE" | tr -d '+[:space:]-')"
echo "📱 Teléfono alerta: $PHONE"
echo

try_url() {
  local url="$1"
  echo -n "Probando $url/api/health ... "
  if curl -sf --max-time 3 "$url/api/health" >/tmp/wa-health.json 2>/dev/null; then
    echo "OK → $(head -c 120 /tmp/wa-health.json)"
    return 0
  fi
  echo "falló"
  return 1
}

CANDIDATES=()

# 1) Puerto publicado en el host
CANDIDATES+=("http://127.0.0.1:3001")
CANDIDATES+=("http://localhost:3001")

# 2) IP del contenedor / task de Swarm
if command -v docker >/dev/null 2>&1; then
  echo "🔎 Buscando contenedores/servicios whatsapp..."
  mapfile -t NAMES < <(docker ps --format '{{.Names}}' 2>/dev/null | grep -i whatsapp || true)
  for name in "${NAMES[@]:-}"; do
    echo "  contenedor: $name"
    ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$name" 2>/dev/null | awk 'NF{print; exit}')"
    if [[ -n "${ip:-}" ]]; then
      echo "  IP: $ip"
      CANDIDATES+=("http://${ip}:3001")
    fi
    # puerto host mapeado
    hp="$(docker port "$name" 3001 2>/dev/null | head -1 | sed 's/.*://' || true)"
    if [[ -n "${hp:-}" ]]; then
      CANDIDATES+=("http://127.0.0.1:${hp}")
    fi
  done

  # Swarm service
  SVC="$(docker service ls --format '{{.Name}}' 2>/dev/null | grep -i whatsapp | head -1 || true)"
  if [[ -n "${SVC:-}" ]]; then
    echo "  service: $SVC"
    TIP="$(docker service inspect "$SVC" --format '{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}' 2>/dev/null | awk '{print $1}' | cut -d/ -f1 || true)"
    if [[ -n "${TIP:-}" ]]; then
      CANDIDATES+=("http://${TIP}:3001")
    fi
  fi
fi

# únicos
mapfile -t CANDIDATES < <(printf '%s\n' "${CANDIDATES[@]}" | awk 'NF && !seen[$0]++')

WA_URL=""
for u in "${CANDIDATES[@]}"; do
  if try_url "$u"; then
    WA_URL="$u"
    break
  fi
done

echo
if [[ -z "$WA_URL" ]]; then
  echo "❌ No pude hablar con WhatsApp desde el host."
  echo "Alternativa: correr el monitor DENTRO de la red Docker (ver abajo)."
  echo
  echo "Comando alternativo (contenedor efímero en red easypanel):"
  echo "  docker run --rm --network easypanel -e MONITOR_ALERT_PHONE=$PHONE \\"
  echo "    -e WHATSAPP_API_URL=http://checkin24hs_whatsapp:3001 \\"
  echo "    -v /root/checkin24hs:/app -w /app node:20-alpine \\"
  echo "    node scripts/site-monitor/monitor.js --digest"
  exit 1
fi

echo "✅ URL WhatsApp: $WA_URL"
echo
echo "Enviando digest..."
cd /root/checkin24hs
MONITOR_ALERT_PHONE="$PHONE" WHATSAPP_API_URL="$WA_URL" node scripts/site-monitor/monitor.js --digest

echo
echo "Para el cron, usá:"
echo "  MONITOR_ALERT_PHONE=$PHONE WHATSAPP_API_URL=$WA_URL node scripts/site-monitor/monitor.js"
