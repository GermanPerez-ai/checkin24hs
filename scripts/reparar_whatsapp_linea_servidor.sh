#!/usr/bin/env bash
# Reparar una línea WhatsApp (default 4) cuando está desconectada / "Esperando mensaje".
#
# Uso en el servidor:
#   bash scripts/reparar_whatsapp_linea_servidor.sh 3
#   bash scripts/reparar_whatsapp_linea_servidor.sh 3 --reset-auth
#   bash scripts/reparar_whatsapp_linea_servidor.sh 3 --hard
#
# --reset-auth: borra archivos de sesión y force update
# --hard: scale 0 → borra volumen → scale 1 (evita 2 contenedores
#         con la misma auth a la vez, causa típica de "Esperando mensaje")

set -euo pipefail

LINE="4"
RESET_AUTH=0
HARD=0
for arg in "$@"; do
  case "$arg" in
    --hard|--hard-reset) HARD=1; RESET_AUTH=1 ;;
    --reset-auth|--reset|--wipe) RESET_AUTH=1 ;;
    [1-4]) LINE="$arg" ;;
    -h|--help)
      echo "Uso: bash scripts/reparar_whatsapp_linea_servidor.sh [1|2|3|4] [--reset-auth|--hard]"
      exit 0
      ;;
    *)
      echo "Arg desconocido: $arg"
      echo "Uso: bash scripts/reparar_whatsapp_linea_servidor.sh [1|2|3|4] [--reset-auth|--hard]"
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
echo "Reset auth: $RESET_AUTH | Hard (scale 0 + wipe volume): $HARD"
echo

echo "1) Estado actual (público):"
curl -sS --max-time 20 "$HOST/api/health" || echo "(health falló / timeout)"
echo
curl -sS --max-time 20 -H 'Accept: application/json' "$HOST/api/status" || echo "(status falló / timeout)"
echo
echo

if [[ "$HARD" -eq 1 ]]; then
  echo "2a) Scale a 0 (apagar TODOS los contenedores de L$LINE)..."
  docker service scale "${SVC}=0"
  echo "   Esperando 8s..."
  sleep 8
  echo "2b) Borrando volumen $VOLUME por completo..."
  docker run --rm -v "${VOLUME}:/wipe" alpine:3.20 sh -c 'rm -rf /wipe/* /wipe/.[!.]* /wipe/..?* 2>/dev/null; ls -la /wipe || true' || true
  echo "2c) Scale a 1 + update-order stop-first..."
  docker service update --replicas 1 --update-order stop-first --force "$SVC" || docker service scale "${SVC}=1"
  echo "   Esperando 35s a QR..."
  sleep 35
elif [[ "$RESET_AUTH" -eq 1 ]]; then
  echo "2) Limpiando sesión Baileys ($AUTH_DIR)..."
  CID="$(docker ps --filter "name=${SVC}" --format '{{.ID}}' | head -1 || true)"
  if [[ -n "${CID:-}" ]]; then
    echo "   Contenedor: $CID"
    docker exec "$CID" sh -c "rm -rf ${AUTH_DIR}/* ${AUTH_DIR}/.[!.]* 2>/dev/null; ls -la ${AUTH_DIR} 2>/dev/null || true" || true
    echo "   ✅ Contenido de auth borrado en el volumen montado"
  else
    echo "   ⚠️ No hay contenedor corriendo; intento borrar vía volumen..."
    docker run --rm -v "${VOLUME}:${AUTH_DIR}" alpine:3.20 sh -c "rm -rf ${AUTH_DIR}/* ${AUTH_DIR}/.[!.]* 2>/dev/null; ls -la ${AUTH_DIR} || true" || true
  fi
  echo
  echo "3) Force update (stop-first)..."
  docker service update --force --update-order stop-first --replicas 1 "$SVC"
  echo "   Esperando 30s a que arranque..."
  sleep 30
else
  echo "2) Force update (stop-first, sin borrar sesión)..."
  docker service update --force --update-order stop-first --replicas 1 "$SVC"
  echo "   Esperando 30s a que arranque..."
  sleep 30
fi

echo
echo "4) Réplicas (debe ser 1/1, un solo task):"
docker service ls | grep -E "whatsapp|NAME" || true
docker service ps "$SVC" --no-trunc 2>/dev/null | head -8 || true
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
if echo "$ST" | grep -q '"qrCode":"data:image'; then
  echo "📱 Hay QR — abrí $HOST/qr o Dashboard → Flor → WhatsApp → Línea $LINE"
elif echo "$ST" | grep -qE '"connected":true'; then
  CONNECTED=1
fi

echo
echo "6) Últimos logs (buscar @lid / message not available / Bad MAC):"
docker service logs "$SVC" --tail 50 2>&1 | tail -50 || true
echo

if [[ "$CONNECTED" -eq 1 ]]; then
  echo "✅ Listo: Línea $LINE en open/connected."
  echo "Probá un chat NUEVO (número que nunca escribió, o borrá el chat en ambos lados)."
  exit 0
fi

echo "=== Siguiente paso: escanear QR (UNA sola sesión vinculada) ==="
echo "1. En el celular L$LINE: Dispositivos vinculados → CERRAR TODOS."
echo "2. No uses WhatsApp Web en otra PC con este número."
echo "3. Abrí: $HOST/qr  y vinculá UNA vez."
echo "4. Esperá 2 min. Verificá: curl -s $HOST/api/status"
echo "5. Mandá 'hola' desde un teléfono de prueba y mirá logs:"
echo "   docker service logs $SVC --tail 80 | grep -E 'JID final|@lid|message not available|Flor OUT|Bad MAC'"
echo
if [[ "$HARD" -eq 0 ]]; then
  echo "Si sigue 'Esperando mensaje' tras el QR, usá el hard reset:"
  echo "  bash scripts/reparar_whatsapp_linea_servidor.sh $LINE --hard"
fi
echo
echo "Puerto interno Swarm: $PORT · volumen: $VOLUME · servicio $SVC"
