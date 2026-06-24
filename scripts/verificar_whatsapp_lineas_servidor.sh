#!/bin/bash
# Diagnóstico rápido Líneas WhatsApp 1–4 (servicios Swarm + health + SSL).
# Uso: cd /root/checkin24hs && bash scripts/verificar_whatsapp_lineas_servidor.sh

set -euo pipefail

check_line() {
  local line="$1"
  local host="whatsapp${line}.checkin24hs.com"
  local port=$((3000 + line))
  local service="checkin24hs_whatsapp${line}"
  [[ "$line" == "1" ]] && host="whatsapp.checkin24hs.com" && service="checkin24hs_whatsapp"

  echo ""
  echo "========== Línea $line ($host :$port) =========="

  if docker service inspect "$service" >/dev/null 2>&1; then
    local replicas
    replicas=$(docker service ls --filter "name=${service}" --format '{{.Replicas}}' 2>/dev/null || echo "?")
    echo "Servicio: $service — réplicas $replicas"
  else
    echo "❌ Servicio $service NO existe. Corré: bash scripts/deploy_whatsapp_linea_servidor.sh $line"
    return
  fi

  echo -n "Health público (HTTPS): "
  if curl -sf -m 12 "https://${host}/api/health" >/dev/null 2>&1; then
    echo "OK"
    curl -s -m 12 "https://${host}/api/health" | head -c 200
    echo ""
  elif curl -skf -m 12 "https://${host}/api/health" >/dev/null 2>&1; then
    echo "⚠️  responde pero certificado SSL inválido/vencido"
    curl -sk -m 12 "https://${host}/api/health" | head -c 200
    echo ""
    echo "   → bash scripts/aplicar_traefik_whatsapp_ambos.sh y esperá ~2 min"
  else
    echo "FAIL (sin respuesta)"
  fi

  echo -n "Health interno (red Docker): "
  if docker run --rm --network easypanel curlimages/curl:8.5.0 -sf -m 10 "http://${service}:${port}/api/health" 2>/dev/null; then
    echo ""
  else
    echo "FAIL — revisá que el servicio esté en red easypanel"
  fi
}

for line in 1 2 3 4; do
  check_line "$line"
done

echo ""
echo "Proxy dashboard (debe responder JSON, no 502):"
for line in 1 2 3 4; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 "https://dashboard.checkin24hs.com/api/whatsapp-status/${line}" || echo "000")
  echo "  /api/whatsapp-status/$line → HTTP $code"
done
