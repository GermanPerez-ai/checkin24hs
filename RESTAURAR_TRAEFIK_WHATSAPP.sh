#!/bin/bash
# Configurar Traefik para api1.checkin24hs.com → checkin24hs_whatsapp (puerto 3001)
# Ejecutar EN EL SERVIDOR por SSH. Soluciona 404 + CORS al conectar WhatsApp desde el dashboard.

set -e
echo "=========================================="
echo "🔧 TRAEFIK → api1.checkin24hs.com (WhatsApp)"
echo "=========================================="
echo ""

SERVICE="checkin24hs_whatsapp"

if ! docker service ls | grep -q "$SERVICE"; then
    echo "❌ Servicio $SERVICE no encontrado."
    echo "   Crea o despliega el servicio WhatsApp antes de ejecutar este script."
    exit 1
fi

echo "📋 Servicio encontrado: $SERVICE"
echo "   Labels actuales de Traefik:"
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "traefik|api1" || echo "   (ninguno)"
echo ""
echo "🔧 Agregando labels de Traefik (websecure + TLS)..."
echo ""

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp-api1.rule=Host(\`api1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp-api1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp-api1.tls=true" \
  --label-add "traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp-api1.loadbalancer.server.port=3001" \
  $SERVICE

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Labels aplicados correctamente"
else
    echo "❌ Error al agregar labels"
    exit 1
fi

echo ""
echo "📋 Verificando labels..."
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik
echo ""
echo "⏳ Espera 30–60 segundos para que Traefik y Let's Encrypt apliquen los cambios."
echo ""
echo "🔍 Verificar (en el servidor):"
echo "   curl -sI https://api1.checkin24hs.com/api/status | head -5"
echo "   curl -s https://api1.checkin24hs.com/api/status"
echo ""
echo "🌐 Luego en el dashboard:"
echo "   https://dashboard.checkin24hs.com → Flor IA → WhatsApp"
echo "   URL: https://api1.checkin24hs.com → Guardar → Conectar"
echo ""
