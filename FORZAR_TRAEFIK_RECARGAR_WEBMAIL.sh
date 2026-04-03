#!/bin/bash
# Verificar labels actuales, reiniciar Traefik y probar desde el servidor

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=== 1. Labels ACTUALES del servicio webmail ==="
docker service inspect $SERVICE_NAME --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | sort
echo ""

echo "=== 2. IP actual del contenedor ==="
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker inspect $CONTAINER_ID --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}} {{end}}'
echo ""

echo "=== 3. Probar desde el SERVIDOR (sin cache del navegador) ==="
echo "    HTTPS:"
curl -s -o /dev/null -w "    %{http_code}\n" -k -H "Host: $DOMAIN" "https://127.0.0.1/$DOMAIN/" 2>/dev/null || curl -s -o /dev/null -w "    %{http_code}\n" -k "https://$DOMAIN/"
echo "    (si 000 = no llega; 404 = Traefik responde 404)"
echo ""

echo "=== 4. Reiniciar Traefik para que recargue labels ==="
TRAEFIK_SERVICE=$(docker service ls --format '{{.Name}}' | grep -i traefik | head -1)
echo "    Servicio: $TRAEFIK_SERVICE"
docker service update --force $TRAEFIK_SERVICE
echo ""
echo "    Espera 30 segundos y luego prueba de nuevo en incognito: https://$DOMAIN/"
echo ""

echo "=== 5. Si sigue 404: probar acceso directo al contenedor desde Traefik ==="
echo "    (Traefik debe poder hacer curl a la IP del webmail)"
WEBMAIL_IP=$(docker inspect $CONTAINER_ID --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}} {{end}}' | awk '{print $1}')
echo "    IP webmail: $WEBMAIL_IP"
TRAEFIK_ID=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
docker exec $TRAEFIK_ID wget -qO- --timeout=3 "http://${WEBMAIL_IP}:80/" 2>/dev/null | head -3 || echo "    Traefik no pudo conectar a $WEBMAIL_IP:80"
echo ""
echo "=== Listo ==="
