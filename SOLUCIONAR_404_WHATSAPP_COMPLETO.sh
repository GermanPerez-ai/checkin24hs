#!/bin/bash
# Solución completa para el error 404 de WhatsApp

echo "=== SOLUCIONANDO ERROR 404 PARA WHATSAPP ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"

# 1. Verificar servicio
echo "1️⃣ Verificando servicio..."
if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "❌ Servicio $SERVICE_NAME no encontrado"
    exit 1
fi
echo "✅ Servicio encontrado"

# 2. Verificar y agregar a red easypanel
echo ""
echo "2️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
if ! echo "$NETWORKS" | grep -qi "easypanel"; then
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 3
    echo "   ✅ Agregado a red easypanel"
else
    echo "   ✅ Ya está en red easypanel"
fi

# 3. Aplicar labels de Traefik
echo ""
echo "3️⃣ Aplicando labels de Traefik..."
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)' \
  --label-add 'traefik.http.routers.whatsapp.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp.tls=true' \
  --label-add 'traefik.http.routers.whatsapp.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.services.whatsapp.loadbalancer.server.port=3001' \
  $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true

if [ $? -eq 0 ]; then
    echo "✅ Labels aplicadas"
else
    echo "❌ Error al aplicar labels"
    exit 1
fi

# 4. Verificar labels
echo ""
echo "4️⃣ Verificando labels aplicadas..."
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

# 5. Verificar Traefik
echo ""
echo "5️⃣ Verificando Traefik..."
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik encontrado: $TRAEFIK_CONTAINER"
    echo ""
    echo "Esperando 15 segundos para que Traefik detecte los cambios..."
    sleep 15
    echo ""
    echo "Buscando rutas en Traefik..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp\|${DOMAIN}" || echo "   ⚠️  Aún no aparece (puede tardar más)"
else
    echo "❌ Traefik no encontrado"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN APLICADA"
echo "=========================================="
echo ""
echo "⏳ Espera 30-60 segundos y prueba:"
echo "   https://whatsapp.checkin24hs.com/status"
echo "   https://whatsapp.checkin24hs.com/api/status"
echo ""
echo "⚠️  IMPORTANTE: Si sigue dando 404, configura el dominio en EasyPanel:"
echo "   1. Ve a EasyPanel → Servicio 'whatsapp'"
echo "   2. Pestaña 'Dominios'"
echo "   3. Agrega: whatsapp.checkin24hs.com"
echo "   4. Guarda y espera 1-2 minutos"
echo ""
