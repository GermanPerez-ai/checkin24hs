#!/bin/bash
# Aplicar labels de webmail igual que dashboard/cotizador: solo puerto + red, sin IP fija

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "Quitando label con IP fija y aplicando formato como dashboard/cotizador..."
echo ""

# Quitar la label que fija la IP (si existe)
docker service update --label-rm "traefik.http.services.webmail.loadbalancer.server" $SERVICE_NAME 2>/dev/null || true

echo "Esperando 5 s..."
sleep 5

echo "Anadiendo labels: puerto 80, red easypanel, TLS como los demas..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail.tls=true" \
  --label-add "traefik.http.routers.webmail.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  $SERVICE_NAME

echo ""
echo "Listo. Espera 20 segundos y prueba:"
echo "  curl -sI -k https://webmail.checkin24hs.com/ | head -3"
echo ""
echo "Traefik descubrira la IP del contenedor por Swarm; no hace falta fijar la IP."
