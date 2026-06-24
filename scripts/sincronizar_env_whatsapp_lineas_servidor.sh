#!/bin/bash
# Copia variables de entorno de Flor/WhatsApp desde Línea 1 a L2/L3/L4.
# Las líneas nuevas creadas con deploy_whatsapp_linea_servidor.sh solo tenían PORT e INSTANCE_NUMBER.
# Uso: cd /root/checkin24hs && bash scripts/sincronizar_env_whatsapp_lineas_servidor.sh [2|3|4|all]

set -euo pipefail
cd "$(dirname "$0")/.."

SOURCE="${WHATSAPP_ENV_SOURCE:-checkin24hs_whatsapp}"
TARGETS="${1:-all}"

if ! docker service inspect "$SOURCE" >/dev/null 2>&1; then
  echo "❌ Servicio origen no encontrado: $SOURCE"
  exit 1
fi

sync_line() {
  local line="$1"
  local target="checkin24hs_whatsapp${line}"
  local port=$((3000 + line))

  if ! docker service inspect "$target" >/dev/null 2>&1; then
    echo "⏭️  L$line: servicio $target no existe, omitiendo"
    return
  fi

  echo ""
  echo "=== Sincronizando env → Línea $line ($target, puerto $port) ==="

  mapfile -t SRC_ENV < <(
    docker service inspect "$SOURCE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null \
      | grep -v '^$' || true
  )

  if [ "${#SRC_ENV[@]}" -eq 0 ]; then
    echo "⚠️  Sin variables en $SOURCE"
    return
  fi

  ENV_ADD=()
  ENV_RM=()
  for entry in "${SRC_ENV[@]}"; do
    local key="${entry%%=*}"
    [[ "$key" == "INSTANCE_NUMBER" || "$key" == "PORT" ]] && continue
    ENV_RM+=(--env-rm "$key")
    ENV_ADD+=(--env-add "$entry")
  done

  ENV_ADD+=(--env-add "INSTANCE_NUMBER=${line}")
  ENV_ADD+=(--env-add "PORT=${port}")

  # Quitar duplicados de env-rm (docker acepta repetidos pero es más limpio)
  docker service update \
    --update-order stop-first \
    "${ENV_RM[@]}" \
    "${ENV_ADD[@]}" \
    "$target"

  echo "✅ L$line actualizada"
  echo -n "   GEMINI_API_KEY: "
  if docker service inspect "$target" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -q '^GEMINI_API_KEY=.\+$'; then
    echo "definida"
  else
    echo "❌ VACÍA — configurá en EasyPanel en $SOURCE y volvé a correr este script"
  fi
}

case "$TARGETS" in
  all) for line in 2 3 4; do sync_line "$line"; done ;;
  2|3|4) sync_line "$TARGETS" ;;
  *)
    echo "Uso: bash scripts/sincronizar_env_whatsapp_lineas_servidor.sh [2|3|4|all]"
    exit 1
    ;;
esac

echo ""
echo "=== Reiniciando tareas (force) para aplicar env ==="
for line in 2 3 4; do
  target="checkin24hs_whatsapp${line}"
  docker service inspect "$target" >/dev/null 2>&1 && docker service update --force "$target" || true
done

echo ""
echo "Esperá ~40s y probá un mensaje en cada línea."
echo "Logs L3: docker service logs checkin24hs_whatsapp3 --tail 50 | grep -iE 'Mensaje recibido|Flor|GEMINI|Error'"
