#!/bin/bash
cd /root/checkin24hs
echo "=========================================="
echo "🔧 SOLUCIONANDO WEBMAIL BAD GATEWAY"
echo "=========================================="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
echo "Red encontrada: $EASYPANEL_NET"
docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
sleep 10
docker service update --label-add "traefik.enable=true" --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" --label-add "traefik.http.routers.webmail.entrypoints=web" --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" checkin24hs_webmail
sleep 15
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "El webmail debería estar accesible en: http://webmail.checkin24hs.com"
