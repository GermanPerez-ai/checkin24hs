#!/bin/bash
# Aplicar configuración de Traefik manualmente para WhatsApp

echo "=== APLICANDO CONFIGURACIÓN TRAEFIK MANUAL ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"

# 1. Verificar servicio
if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "❌ Servicio no encontrado"
    exit 1
fi
echo "✅ Servicio encontrado: $SERVICE_NAME"

# 2. Verificar y agregar a red easypanel
echo ""
echo "2️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
if ! echo "$NETWORKS" | grep -qi "easypanel"; then
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 3
fi
echo "   ✅ En red easypanel"

# 3. Aplicar labels de Traefik (usando nombres que no entren en conflicto con EasyPanel)
echo ""
echo "3️⃣ Aplicando labels de Traefik..."
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add "traefik.http.routers.whatsapp-main.rule=Host(\`${DOMAIN}\`)" \
  --label-add 'traefik.http.routers.whatsapp-main.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp-main.tls=true' \
  --label-add 'traefik.http.routers.whatsapp-main.tls.certresolver=letsencrypt' \
  --label-add "traefik.http.services.whatsapp-main.loadbalancer.server.port=${PORT}" \
  $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true

echo "✅ Labels aplicadas"

# 4. Verificar labels
echo ""
echo "4️⃣ Labels aplicadas:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

# 5. Esperar y verificar Traefik
echo ""
echo "5️⃣ Esperando 30 segundos para que Traefik detecte..."
sleep 30

TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo ""
    echo "6️⃣ Verificando en Traefik..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp\|${DOMAIN}" || echo "   ⚠️  Aún no aparece (puede tardar más)"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN APLICADA"
echo "=========================================="
echo ""
echo "⏳ Espera 1-2 minutos y prueba:"
echo "   https://whatsapp.checkin24hs.com/status"
echo "   https://whatsapp.checkin24hs.com/qr"
echo ""
