#!/bin/bash
# Último diagnóstico 404: Traefik, labels y prueba directa

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== 1. Label loadbalancer (debe ser 10.0.1.6:80) ==="
docker service inspect $SERVICE_NAME --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep loadbalancer
echo ""

echo "=== 2. Reiniciar Traefik para forzar recarga ==="
docker service update --force $(docker service ls -q --filter name=traefik)
echo "Espera 30 segundos..."
sleep 30
echo ""

echo "=== 3. Prueba HTTPS ==="
curl -sI -k "https://$DOMAIN/" | head -5
echo ""

echo "=== 4. Prueba HTTP (puerto 80) por si el router solo está en web ==="
curl -sI "http://$DOMAIN/" 2>/dev/null | head -5 || echo "(fallo o redirect)"
echo ""

echo "=== 5. Logs Traefik (últimas 15 líneas al hacer la petición) ==="
curl -s -o /dev/null -k "https://$DOMAIN/"
docker service logs $(docker service ls -q --filter name=traefik) --tail 20 2>&1 | tail -15
echo ""

echo "=== 6. ¿Traefik puede llegar al backend 10.0.1.6:80? ==="
TRAEFIK_ID=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
docker exec $TRAEFIK_ID wget -qO- --timeout=2 "http://10.0.1.6:80/" 2>/dev/null | head -2 || echo "Traefik NO pudo conectar a 10.0.1.6:80"
