#!/usr/bin/env bash
# Reparar una línea WhatsApp (default 4) cuando está desconectada / sin responder.
# Uso en el servidor:
#   bash scripts/reparar_whatsapp_linea_servidor.sh 4
#
# 1) Fuerza recreate del servicio Swarm
# 2) Muestra health/status
# 3) Si sigue close: hay que escanear QR (Dashboard → Flor IA → WhatsApp → Línea N)
#    o abrir https://whatsappN.checkin24hs.com/qr

set -euo pipefail
LINE="${1:-4}"
if ! [[ "$LINE" =~ ^[1-4]$ ]]; then
  echo "Uso: bash scripts/reparar_whatsapp_linea_servidor.sh [1|2|3|4]"
  exit 1
fi

if [[ "$LINE" == "1" ]]; then
  SVC="checkin24hs_whatsapp"
  HOST="https://whatsapp.checkin24hs.com"
  PORT=3001
else
  SVC="checkin24hs_whatsapp${LINE}"
  HOST="https://whatsapp${LINE}.checkin24hs.com"
  PORT=$((3000 + LINE))
fi

echo "=== Reparar WhatsApp Línea $LINE ==="
echo "Servicio: $SVC"
echo "URL: $HOST"
echo

echo "1) Estado actual (público):"
curl -sS --max-time 20 "$HOST/api/health" || echo "(health falló / timeout)"
echo
curl -sS --max-time 20 -H 'Accept: application/json' "$HOST/api/status" || echo "(status falló / timeout)"
echo
echo

echo "2) Force update del servicio..."
docker service update --force "$SVC"
echo "   Esperando 25s a que arranque..."
sleep 25

echo "3) Réplicas:"
docker service ls | grep -E "whatsapp|NAME" || true
echo

echo "4) Health post-restart:"
for i in 1 2 3 4 5; do
  if OUT=$(curl -sS --max-time 15 "$HOST/api/health" 2>/dev/null); then
    echo "$OUT"
    if echo "$OUT" | grep -qE '"whatsapp":"(open|connected)"'; then
      echo "✅ Línea $LINE conectada."
      exit 0
    fi
    if echo "$OUT" | grep -qE '"whatsapp":"(close|connecting)"'; then
      echo "⚠️ Servicio vivo pero WhatsApp aún no open. Puede necesitar QR."
      break
    fi
  else
    echo "   intento $i: sin respuesta todavía..."
  fi
  sleep 5
done

echo
echo "5) Últimos logs (buscar QR / logged out / conflict):"
docker service logs "$SVC" --tail 60 2>&1 | tail -60 || true
echo
echo "=== Si sigue disconnected ==="
echo "1. Abrí Dashboard → Flor IA → pestaña WhatsApp → tarjeta Línea $LINE"
echo "2. O en el navegador: $HOST/qr  (Accept HTML) / $HOST/api/qr"
echo "3. Escaneá el QR con el celular de esa línea."
echo "4. Verificá: curl -s $HOST/api/status"
echo "5. Sync env Flor si hace falta: bash scripts/sincronizar_env_whatsapp_lineas_servidor.sh $LINE"
echo
echo "Puerto interno Swarm: $PORT · servicio $SVC"
