#!/bin/bash
# Verificar si Traefik detecta el contenedor

echo "=== 1. Verificar redes del contenedor proxy ==="
docker inspect dashboard-nginx-proxy | grep -A 5 "Networks"

echo ""
echo "=== 2. Verificar redes de Traefik ==="
docker inspect traefik.1.1qfkazdh5m0czg2hslan0ny0g | grep -A 5 "Networks"

echo ""
echo "=== 3. Verificar si están en la misma red ==="
PROXY_NETWORKS=$(docker inspect dashboard-nginx-proxy --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}')
TRAEFIK_NETWORKS=$(docker inspect traefik.1.1qfkazdh5m0czg2hslan0ny0g --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}')
echo "Redes del proxy: $PROXY_NETWORKS"
echo "Redes de Traefik: $TRAEFIK_NETWORKS"

echo ""
echo "=== 4. Ver logs de Traefik recientes ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 30 | tail -15

echo ""
echo "=== 5. Probar acceso desde Traefik al contenedor proxy ==="
PROXY_IP=$(docker inspect dashboard-nginx-proxy --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP del proxy: $PROXY_IP"
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- --timeout=3 http://$PROXY_IP:80 2>&1 | head -3 || echo "No se puede acceder"

echo ""
echo "=== 6. Verificar API de Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard || echo "No se encontró router"

