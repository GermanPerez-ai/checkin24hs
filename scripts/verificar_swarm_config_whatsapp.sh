#!/bin/bash
# Verificar configuración Docker Swarm de las 4 líneas WhatsApp
# para prevenir acceso concurrente a auth que causa "Esperando mensaje"
#
# Uso: cd /root/checkin24hs && bash scripts/verificar_swarm_config_whatsapp.sh

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 Verificación Configuración Swarm WhatsApp"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ERRORS=0
WARNINGS=0

for LINE in 1 2 3 4; do
  SERVICE="checkin24hs_whatsapp"
  [[ $LINE -gt 1 ]] && SERVICE="${SERVICE}${LINE}"
  
  echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "┃ Línea $LINE: $SERVICE"
  echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if ! docker service inspect "$SERVICE" >/dev/null 2>&1; then
    echo "❌ Servicio NO existe"
    echo "   Crear con: bash scripts/deploy_whatsapp_linea_servidor.sh $LINE"
    echo ""
    ((ERRORS++)) || true
    continue
  fi
  
  # 1. Replicas
  REPLICAS=$(docker service inspect "$SERVICE" --format '{{.Spec.Mode.Replicated.Replicas}}' 2>/dev/null || echo "?")
  if [[ "$REPLICAS" == "1" ]]; then
    echo "✅ Replicas: $REPLICAS"
  else
    echo "❌ Replicas: $REPLICAS (DEBE SER 1)"
    echo "   ⚠️  CRÍTICO: >1 réplica = múltiples containers acceden misma auth"
    echo "   → Causa Bad MAC / 'Esperando mensaje' en 100% de mensajes"
    ((ERRORS++)) || true
  fi
  
  # 2. Update order
  ORDER=$(docker service inspect "$SERVICE" --format '{{.Spec.UpdateConfig.Order}}' 2>/dev/null || echo "")
  if [[ "$ORDER" == "stop-first" ]]; then
    echo "✅ Update order: $ORDER"
  elif [[ "$ORDER" == "start-first" ]]; then
    echo "❌ Update order: $ORDER (DEBE SER stop-first)"
    echo "   ⚠️  CRÍTICO: Durante deploy, container viejo y nuevo acceden auth simultáneamente"
    echo "   → Causa corrupción de sesión durante ~30 segundos"
    ((ERRORS++)) || true
  elif [[ -z "$ORDER" ]]; then
    echo "⚠️  Update order: no configurado (default es start-first)"
    echo "   → Debería ser stop-first para evitar acceso concurrente"
    ((WARNINGS++)) || true
  else
    echo "⚠️  Update order: $ORDER (esperado stop-first)"
    ((WARNINGS++)) || true
  fi
  
  # 3. Parallelism
  PARALLEL=$(docker service inspect "$SERVICE" --format '{{.Spec.UpdateConfig.Parallelism}}' 2>/dev/null || echo "")
  if [[ "$PARALLEL" == "1" || -z "$PARALLEL" ]]; then
    echo "✅ Update parallelism: ${PARALLEL:-1} (default)"
  else
    echo "⚠️  Update parallelism: $PARALLEL (debería ser 1)"
    ((WARNINGS++)) || true
  fi
  
  # 4. Instance number
  INSTANCE=$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep INSTANCE_NUMBER | cut -d= -f2 || echo "")
  EXPECTED_INSTANCE="$LINE"
  if [[ "$INSTANCE" == "$EXPECTED_INSTANCE" ]]; then
    echo "✅ INSTANCE_NUMBER: $INSTANCE"
  elif [[ -z "$INSTANCE" && "$LINE" == "1" ]]; then
    echo "✅ INSTANCE_NUMBER: (no set, usa default 1)"
  elif [[ -z "$INSTANCE" ]]; then
    echo "⚠️  INSTANCE_NUMBER: no configurado (esperado $EXPECTED_INSTANCE)"
    ((WARNINGS++)) || true
  else
    echo "❌ INSTANCE_NUMBER: $INSTANCE (esperado $EXPECTED_INSTANCE)"
    ((ERRORS++)) || true
  fi
  
  # 5. Port
  PORT_ENV=$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^PORT=" | cut -d= -f2 || echo "")
  EXPECTED_PORT="300$LINE"
  if [[ "$PORT_ENV" == "$EXPECTED_PORT" ]]; then
    echo "✅ PORT: $PORT_ENV"
  elif [[ -z "$PORT_ENV" && "$LINE" == "1" ]]; then
    echo "✅ PORT: (no set, usa default 3001)"
  elif [[ -z "$PORT_ENV" ]]; then
    echo "⚠️  PORT: no configurado (esperado $EXPECTED_PORT)"
    ((WARNINGS++)) || true
  else
    echo "⚠️  PORT: $PORT_ENV (esperado $EXPECTED_PORT)"
    ((WARNINGS++)) || true
  fi
  
  # 6. Mounts/Volumes
  echo "📂 Volúmenes:"
  MOUNTS=$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}}→{{.Target}}|{{end}}' 2>/dev/null || echo "")
  if [[ -n "$MOUNTS" ]]; then
    IFS='|' read -ra MOUNT_ARRAY <<< "$MOUNTS"
    for MOUNT in "${MOUNT_ARRAY[@]}"; do
      if [[ -z "$MOUNT" ]]; then continue; fi
      SRC=$(echo "$MOUNT" | cut -d'→' -f1)
      TGT=$(echo "$MOUNT" | cut -d'→' -f2)
      
      # Check if target is auth directory
      if [[ "$TGT" == *"auth_info_baileys"* ]]; then
        EXPECTED_AUTH_DIR="/app/auth_info_baileys_${LINE}"
        if [[ "$TGT" == "$EXPECTED_AUTH_DIR" ]]; then
          echo "   ✅ $SRC → $TGT"
        else
          echo "   ⚠️  $SRC → $TGT (esperado $EXPECTED_AUTH_DIR)"
          ((WARNINGS++)) || true
        fi
        
        # Check for duplicate auth volumes across services
        if [[ "$LINE" -gt 1 ]]; then
          for OTHER_LINE in $(seq 1 $((LINE - 1))); do
            OTHER_SERVICE="checkin24hs_whatsapp"
            [[ $OTHER_LINE -gt 1 ]] && OTHER_SERVICE="${OTHER_SERVICE}${OTHER_LINE}"
            
            if docker service inspect "$OTHER_SERVICE" >/dev/null 2>&1; then
              OTHER_SRC=$(docker service inspect "$OTHER_SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if contains "auth_info" .Target}}{{.Source}}{{end}}{{end}}' 2>/dev/null || echo "")
              if [[ "$SRC" == "$OTHER_SRC" && -n "$SRC" ]]; then
                echo "   ❌ CONFLICTO: $SERVICE y $OTHER_SERVICE usan mismo volumen $SRC"
                echo "      → Causa corrupción de sesión / Bad MAC"
                ((ERRORS++)) || true
              fi
            fi
          done
        fi
      else
        echo "   ℹ️  $SRC → $TGT"
      fi
    done
  else
    echo "   ⚠️  No hay volúmenes montados (auth se perderá en restart)"
    ((WARNINGS++)) || true
  fi
  
  # 7. Running tasks
  RUNNING=$(docker service ps "$SERVICE" --filter "desired-state=running" --format "{{.CurrentState}}" 2>/dev/null | head -1)
  if [[ -n "$RUNNING" ]]; then
    echo "🏃 Estado: $RUNNING"
  else
    echo "⚠️  No hay tasks running"
  fi
  
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Resumen"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "✅ Configuración perfecta - sin errores ni advertencias"
  echo ""
  echo "Próximos pasos:"
  echo "  1. Implementar cambios de código del PR #7"
  echo "  2. Verificar con: bash scripts/verificar_whatsapp_lineas_servidor.sh"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠️  $WARNINGS advertencia(s) encontrada(s)"
  echo ""
  echo "Las advertencias no son críticas pero deberían corregirse."
  exit 0
else
  echo "❌ $ERRORS error(es) CRÍTICO(S) encontrado(s)"
  [[ $WARNINGS -gt 0 ]] && echo "⚠️  $WARNINGS advertencia(s) adicional(es)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🔧 Acciones de Corrección"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Para corregir errores:"
  echo ""
  echo "1. Editar el docker-compose correspondiente:"
  echo "   - docker-compose-whatsapp-only.yml (línea 1)"
  echo "   - docker-compose-whatsapp2-only.yml (línea 2)"
  echo "   - docker-compose-whatsapp3-only.yml (línea 3)"
  echo "   - docker-compose-whatsapp4-only.yml (línea 4)"
  echo ""
  echo "2. Asegurar configuración:"
  echo "   deploy:"
  echo "     replicas: 1              # ← DEBE SER 1"
  echo "     update_config:"
  echo "       order: stop-first      # ← DEBE SER stop-first"
  echo "       parallelism: 1"
  echo ""
  echo "3. Redesplegar servicio:"
  echo "   docker stack deploy -c docker-compose-whatsappN-only.yml checkin24hs"
  echo ""
  echo "4. Verificar:"
  echo "   bash scripts/verificar_swarm_config_whatsapp.sh"
  echo ""
  echo "⚠️  NO implementar cambios de código hasta corregir estos errores"
  echo "   → Configuración incorrecta causa 100% de fallos de desencriptación"
  exit 1
fi
