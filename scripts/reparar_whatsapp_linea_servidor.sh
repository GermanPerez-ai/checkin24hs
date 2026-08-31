#!/usr/bin/env bash
# Reparar una línea WhatsApp (default 4) cuando está desconectada / sin responder.
#
# Uso en el servidor:
#   bash scripts/reparar_whatsapp_linea_servidor.sh 4
#   bash scripts/reparar_whatsapp_linea_servidor.sh 4 --reset-auth   # borra sesión + fuerza QR nuevo
#
# --reset-auth: limpia /app/auth_info_baileys_N (volumen) y recrea el servicio.
# Usalo cuando hay bucle 428 / Connection Closed / crypto issues altos sin QR.

set -euo pipefail

LINE="4"
RESET_AUTH=0
for arg in "$@"; do
  case "$arg" in
    --reset-auth|--reset|--wipe) RESET_AUTH=1 ;;
    [1-4]) LINE="$arg" ;;
    -h|--help)
      echo "Uso: bash scripts/reparar_whatsapp_linea_servidor.sh [1|2|3|4] [--reset-auth]"
      exit 0
      ;;
    *)
      echo "Arg desconocido: $arg"
      echo "Uso: bash scripts/reparar_whatsapp_linea_servidor.sh [1|2|3|4] [--reset-auth]"
      exit 1
      ;;
  esac
done

if [[ "$LINE" == "1" ]]; then
  SVC="checkin24hs_whatsapp"
  HOST="https://whatsapp.checkin24hs.com"
  PORT=3001
  VOLUME="whatsapp-auth"
else
  SVC="checkin24hs_whatsapp${LINE}"
  HOST="https://whatsapp${LINE}.checkin24hs.com"
  PORT=$((3000 + LINE))
  VOLUME="whatsapp${LINE}-auth"
fi

AUTH_DIR="/app/auth_info_baileys_${LINE}"

echo "=== Reparar WhatsApp Línea $LINE ==="
echo "Servicio: $SVC"
echo "URL: $HOST"
echo "Reset auth: $RESET_AUTH"
echo

echo "1) Estado actual (público):"
curl -sS --max-time 20 "$HOST/api/health" || echo "(health falló / timeout)"
echo
curl -sS --max-time 20 -H 'Accept: application/json' "$HOST/api/status" || echo "(status falló / timeout)"
echo
echo

if [[ "$RESET_AUTH" -eq 1 ]]; then
  echo "2) Limpiando sesión Baileys ($AUTH_DIR)..."
  CID="$(docker ps --filter "name=${SVC}" --format '{{.ID}}' | head -1 || true)"
  if [[ -n "${CID:-}" ]]; then
    echo "   Contenedor: $CID"
    docker exec "$CID" sh -c "rm -rf ${AUTH_DIR}/* ${AUTH_DIR}/.[!.]* 2>/dev/null; ls -la ${AUTH_DIR} 2>/dev/null || true" || true
    echo "   ✅ Contenido de auth borrado en el volumen montado"
  else
    echo "   ⚠️ No hay contenedor corriendo; intento borrar vía volumen con contenedor efímero..."
    docker run --rm -v "${VOLUME}:${AUTH_DIR}" alpine:3.20 sh -c "rm -rf ${AUTH_DIR}/* ${AUTH_DIR}/.[!.]* 2>/dev/null; ls -la ${AUTH_DIR} || true" || true
  fi
  echo
  echo "3) Force update del servicio (debe generar QR nuevo)..."
else
  echo "2) Force update del servicio (sin borrar sesión)..."
fi

docker service update --force "$SVC"
echo "   Esperando 30s a que arranque..."
sleep 30

echo
echo "4) Réplicas:"
docker service ls | grep -E "whatsapp|NAME" || true
echo

echo "5) Health / status post-restart:"
CONNECTED=0
for i in 1 2 3 4 5 6; do
  if OUT=$(curl -sS --max-time 15 "$HOST/api/health" 2>/dev/null); then
    echo "health: $OUT"
    if echo "$OUT" | grep -qE '"whatsapp":"(open|connected)"'; then
      echo "✅ Línea $LINE conectada."
      CONNECTED=1
      break
    fi
  else
    echo "   intento $i health: sin respuesta todavía..."
  fi
  sleep 5
done

ST=$(curl -sS --max-time 20 -H 'Accept: application/json' "$HOST/api/status" 2>/dev/null || true)
echo "status: ${ST:-(vacío)}"
if echo "$ST" | grep -q '"qrCode":"http'; then
  echo "📱 Hay QR en /api/status — abrí $HOST/qr o Dashboard → Flor → WhatsApp → Línea $LINE"
elif echo "$ST" | grep -qE '"connected":true'; then
  CONNECTED=1
fi

echo
echo "6) Últimos logs:"
docker service logs "$SVC" --tail 40 2>&1 | tail -40 || true
echo

if [[ "$CONNECTED" -eq 1 ]]; then
  echo "✅ Listo: Línea $LINE en open/connected."
  exit 0
fi

echo "=== Siguiente paso obligatorio: escanear QR ==="
echo "1. En el celular de L$LINE: WhatsApp → Dispositivos vinculados → desvincular sesiones viejas de Checkin si hay."
echo "2. Abrí: $HOST/qr   (o Dashboard → Flor IA → WhatsApp → Línea $LINE)"
echo "3. Vincular dispositivo y escanear YA (QR caduca en ~1–2 min)."
echo "4. No cierres WhatsApp 1–2 minutos."
echo "5. Verificá: curl -s $HOST/api/status"
echo
if [[ "$RESET_AUTH" -eq 0 ]]; then
  echo "Si sigue en close/428/crash sin QR, corré de nuevo CON reset:"
  echo "  bash scripts/reparar_whatsapp_linea_servidor.sh $LINE --reset-auth"
fi
echo
echo "Puerto interno Swarm: $PORT · volumen típico: $VOLUME · servicio $SVC"
