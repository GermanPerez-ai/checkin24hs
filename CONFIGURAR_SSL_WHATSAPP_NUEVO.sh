#!/bin/bash
# Configurar SSL con Traefik para el nuevo servicio WhatsApp
# Dominio: whatsapp.checkin24hs.com
# Puerto: 3001

echo "=== CONFIGURANDO SSL PARA WHATSAPP ==="
echo ""

# Nombre del servicio (ajustar según el nombre real en EasyPanel)
SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"

# Verificar que el servicio existe
echo "🔍 Buscando servicio: $SERVICE_NAME"
if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "⚠️  Servicio $SERVICE_NAME no encontrado"
    echo ""
    echo "Servicios disponibles con 'whatsapp':"
    docker service ls --format "{{.Name}}" | grep -i whatsapp || echo "   (ninguno encontrado)"
    echo ""
    echo "Todos los servicios:"
    docker service ls --format "{{.Name}}" | head -10
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Verificar que está en la red easypanel
echo "🔍 Verificando red easypanel..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if ! echo "$NETWORKS" | grep -q "easypanel"; then
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 3
    echo "   ✅ Agregado a red easypanel"
else
    echo "   ✅ Ya está en red easypanel"
fi
echo ""

# Aplicar labels de Traefik para SSL
echo "🔧 Aplicando labels de Traefik para SSL..."
echo "   Dominio: $DOMAIN"
echo "   Puerto: $PORT"
echo ""

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`${DOMAIN}\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=${PORT}" \
  $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true

if [ $? -eq 0 ]; then
    echo "✅ Labels de Traefik aplicadas correctamente"
else
    echo "❌ Error al aplicar labels"
    exit 1
fi

echo ""
echo "⏳ Espera 2-5 minutos para que Let's Encrypt genere el certificado SSL"
echo ""
echo "🔍 Verifica el estado con:"
echo "   docker service logs $SERVICE_NAME --tail 20"
echo ""
echo "🌐 Una vez configurado, accede a:"
echo "   https://${DOMAIN}/api/qr"
echo "   https://${DOMAIN}/api/status"
echo ""
