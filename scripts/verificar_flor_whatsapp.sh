#!/bin/bash
# Verificar estado de WhatsApp y Flor IA (por qué Flor no responde).
# Ejecutar en el SERVIDOR: cd /root/checkin24hs && bash scripts/verificar_flor_whatsapp.sh

set -e
cd "$(dirname "$0")/.."

echo "=============================================="
echo "  Verificación WhatsApp + Flor IA"
echo "=============================================="
echo ""

# 1. Servicio WhatsApp
echo "--- 1. Servicio WhatsApp ---"
docker service ls 2>/dev/null | grep -E "NAME|whatsapp" || echo "No se encontró servicio WhatsApp (no estás en Swarm o el nombre es otro)."
echo ""

# 2. Réplicas
SVC="checkin24hs_whatsapp"
if docker service ls --format "{{.Name}}" 2>/dev/null | grep -q "^${SVC}$"; then
  REPLICAS=$(docker service ls --format "{{.Replicas}}" --filter "name=${SVC}" 2>/dev/null)
  echo "--- 2. Réplicas ($SVC) ---"
  echo "  $REPLICAS"
  if echo "$REPLICAS" | grep -q "0/"; then
    echo "  ⚠️ El servicio tiene 0 réplicas activas. Necesitás hacer Redeploy o scale 1."
  fi
else
  echo "--- 2. Réplicas ---"
  echo "  Servicio $SVC no encontrado."
fi
echo ""

# 3. Variables de entorno (solo si existen, sin mostrar valores sensibles)
check_flor_env() {
  local svc="$1"
  local label="$2"
  echo "--- 3. Variables Flor ($label: $svc) ---"
  if ! docker service inspect "$svc" >/dev/null 2>&1; then
    echo "  Servicio no encontrado."
    echo ""
    return
  fi
  ENV_FLOR=$(docker service inspect "$svc" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -E "^(FLOR_ENABLED|AUTO_REPLY|GEMINI_API_KEY)=" || true)
  for var in FLOR_ENABLED AUTO_REPLY GEMINI_API_KEY; do
    line=$(echo "$ENV_FLOR" | grep "^${var}=" || true)
    if [ -n "$line" ]; then
      val="${line#*=}"
      if [ "$var" = "GEMINI_API_KEY" ]; then
        [ -n "$val" ] && echo "  ${var}=***definida***" || echo "  ${var}= (vacía) ⚠️ Flor no puede responder sin API key"
      else
        echo "  $line"
      fi
    else
      echo "  ${var}= (no definida; el código usa valor por defecto)"
    fi
  done
  echo ""
}

check_flor_env "checkin24hs_whatsapp" "L1"
check_flor_env "checkin24hs_whatsapp2" "L2"
check_flor_env "checkin24hs_whatsapp3" "L3"
check_flor_env "checkin24hs_whatsapp4" "L4"

# 4. Estado del API (WhatsApp conectado + Flor activa)
echo "--- 4. Estado del servidor WhatsApp L1 (API) ---"
STATUS_JSON=$(docker run --rm --network easypanel curlimages/curl:latest -s -H "Accept: application/json" http://checkin24hs_whatsapp:3001/api/status 2>/dev/null || echo "{}")
if [ "$STATUS_JSON" = "{}" ] || [ -z "$STATUS_JSON" ]; then
  echo "  No se pudo conectar al API (red easypanel o servicio no escuchando en 3001)."
  echo "  Probá desde el navegador: https://whatsapp.checkin24hs.com/api/status"
else
  echo "  $STATUS_JSON"
  echo "$STATUS_JSON" | grep -q '"whatsapp":"connected"' || echo "  ⚠️ WhatsApp no está conectado. Revisá QR en https://whatsapp.checkin24hs.com"
  echo "$STATUS_JSON" | grep -q '"flor":"inactive"' && echo "  ⚠️ Flor está inactiva. Revisá FLOR_ENABLED en EasyPanel."
  echo "$STATUS_JSON" | grep -q '"autoReply":false' && echo "  ⚠️ AUTO_REPLY está en false. Flor no responderá automáticamente."
fi
echo ""

# 5. Últimas líneas de log (errores o Flor respondió)
echo "--- 5. Últimas 35 líneas del log (WhatsApp) ---"
docker service logs "$SVC" --tail 35 2>/dev/null || echo "No se pudieron obtener logs."
echo ""

echo "=============================================="
echo "  Resumen"
echo "=============================================="
echo "  - Si whatsapp != 'connected': escaneá el QR en https://whatsapp.checkin24hs.com"
echo "  - Si flor == 'inactive' o GEMINI_API_KEY vacía: configurá en EasyPanel → servicio WhatsApp → Variables"
echo "  - Si en Supabase flor_ai_config.enabled = false: activá Flor desde el dashboard (Flor IA)."
echo "  - Si L3/L4 no responden Flor: bash scripts/sincronizar_env_whatsapp_lineas_servidor.sh 3"
echo "=============================================="
