#!/bin/bash
# Diagnóstico 404 cotizador: ejecutar en el servidor (ssh root@72.61.58.240)
# Uso: bash VERIFICAR_404_COTIZADOR.sh

set -e
SERVICE_NAME="checkin24hs_cotizador"
DOMAIN="cotizar.checkin24hs.com"

echo "=============================================="
echo "🔍 DIAGNÓSTICO 404 COTIZADOR"
echo "=============================================="
echo ""

echo "1️⃣ Servicio $SERVICE_NAME existe y está corriendo?"
docker service ls --format "{{.Name}}\t{{.Replicas}}\t{{.Image}}" | grep -i cotizador || { echo "   ❌ No se encontró servicio con 'cotizador'"; docker service ls --format "{{.Name}}"; exit 1; }
echo "   ✅ Servicio encontrado"
echo ""

echo "2️⃣ Redes del servicio (debe incluir 'easypanel'):"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null || echo "   (error al leer)"
echo ""

echo "3️⃣ Labels Traefik del cotizador:"
docker service inspect "$SERVICE_NAME" --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "^traefik" | sort || echo "   (ninguna)"
echo ""

echo "4️⃣ Otros servicios con router Host(...checkin24hs...):"
for s in $(docker service ls --format "{{.Name}}" 2>/dev/null); do
  R=$(docker service inspect "$s" --format '{{range $k,$v := .Spec.Labels}}{{if eq $k "traefik.http.routers.dashboard.rule"}}{{$v}}{{end}}{{end}}' 2>/dev/null)
  R2=$(docker service inspect "$s" --format '{{range $k,$v := .Spec.Labels}}{{if or (eq $k "traefik.http.routers.cotizador.rule") (eq $k "traefik.http.routers.cotizador-rule")}}{{$v}}{{end}}{{end}}' 2>/dev/null)
  [ -n "$R" ] && echo "   $s -> dashboard.rule=$R"
  [ -n "$R2" ] && echo "   $s -> cotizador.rule=$R2"
done
echo ""

echo "5️⃣ Tarea (contenedor) del cotizador - nodo y estado:"
docker service ps "$SERVICE_NAME" --no-trunc 2>/dev/null | head -3
echo ""

echo "6️⃣ Puerto interno del cotizador (imagen/nginx suele ser 80):"
docker service inspect "$SERVICE_NAME" --format '{{json .Spec.TaskTemplate.ContainerSpec.Ports}}' 2>/dev/null | head -1
echo ""

echo "7️⃣ Traefik - nombre del servicio y red:"
TRAEFIK_SVC=$(docker service ls --format "{{.Name}}" | grep -i traefik | head -1)
[ -n "$TRAEFIK_SVC" ] && echo "   Servicio Traefik: $TRAEFIK_SVC" && docker service inspect "$TRAEFIK_SVC" --format '   Redes: {{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}'
echo ""

echo "8️⃣ Probar backend directo (IP de una tarea del cotizador):"
COTIZADOR_TASK=$(docker service ps "$SERVICE_NAME" --format "{{.ID}}" --filter "desired-state=running" 2>/dev/null | head -1)
if [ -n "$COTIZADOR_TASK" ]; then
  echo "   Task ID: $COTIZADOR_TASK"
  # En Swarm no hay IP fija por tarea desde fuera; Traefik resuelve por nombre de servicio
  echo "   (Traefik debe resolver por nombre de servicio en la red)"
else
  echo "   ❌ No hay tarea en estado running"
fi
echo ""

echo "=============================================="
echo "✅ Si las labels están bien pero sigue 404:"
echo "   - Probar router con otro nombre (evitar conflicto con EasyPanel):"
echo ""
echo "   docker service update $SERVICE_NAME \\"
echo "     --label-add 'traefik.http.routers.cotizador-https.rule=Host(\`$DOMAIN\`)' \\"
echo "     --label-add 'traefik.http.routers.cotizador-https.entrypoints=websecure' \\"
echo "     --label-add 'traefik.http.routers.cotizador-https.service=cotizador-svc' \\"
echo "     --label-add 'traefik.http.routers.cotizador-https.tls=true' \\"
echo "     --label-add 'traefik.http.routers.cotizador-https.tls.certresolver=letsencrypt' \\"
echo "     --label-add 'traefik.http.services.cotizador-svc.loadbalancer.server.port=80'"
echo ""
echo "   Luego: docker service update --force traefik"
echo "   Esperar 1-2 min y probar: https://$DOMAIN/"
echo "=============================================="
