#!/bin/bash
# Verificar y corregir el error 502 del dashboard

echo "=== VERIFICANDO Y CORRIGIENDO ERROR 502 ==="
echo ""

sleep 5

echo "1. Verificando acceso HTTPS..."
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com 2>&1)
echo "   HTTP Code: $HTTPS_CODE"

if [ "$HTTPS_CODE" = "200" ]; then
    echo "   ✅ Dashboard funciona correctamente!"
    exit 0
fi

echo ""
echo "2. Obteniendo VIP del servicio en la red easypanel..."
EASYPANEL_NET_ID=$(docker network inspect easypanel --format '{{.Id}}' 2>/dev/null)
if [ -z "$EASYPANEL_NET_ID" ]; then
    echo "   ❌ No se encontró la red easypanel"
    exit 1
fi

VIP=$(docker service inspect checkin24hs_dashboard --format "{{range .Endpoint.VirtualIPs}}{{if eq .NetworkID \"$EASYPANEL_NET_ID\"}}{{.Addr}}{{end}}{{end}}" 2>/dev/null | cut -d/ -f1)

if [ -n "$VIP" ]; then
    echo "   ✅ VIP encontrado: $VIP"
    echo ""
    echo "3. Actualizando Traefik para usar VIP..."
    docker service update \
      --label-rm "traefik.http.services.dashboard.loadbalancer.server" \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://${VIP}:80" \
      checkin24hs_dashboard
    
    echo "   ✅ Actualizado a usar VIP: http://${VIP}:80"
    echo "   ⏳ Esperando 15 segundos para que Traefik recargue..."
    sleep 15
    
    echo ""
    echo "4. Verificando acceso HTTPS nuevamente..."
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com 2>&1)
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "   ✅ Dashboard funciona correctamente con VIP!"
    else
        echo "   ❌ Aún hay problemas (HTTP $HTTPS_CODE)"
        echo ""
        echo "5. Verificando conectividad desde Traefik..."
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
        if [ -n "$TRAEFIK_CONTAINER" ]; then
            echo "   Probando conexión desde Traefik al dashboard..."
            docker exec $TRAEFIK_CONTAINER wget -O- --timeout=5 http://${VIP}:80/dashboard.html 2>&1 | head -5 || \
            docker exec $TRAEFIK_CONTAINER wget -O- --timeout=5 http://checkin24hs_dashboard:80/dashboard.html 2>&1 | head -5
        fi
    fi
else
    echo "   ❌ No se pudo obtener VIP"
    echo ""
    echo "   Intentando usar nombre del servicio directamente..."
    docker service update \
      --label-rm "traefik.http.services.dashboard.loadbalancer.server" \
      --label-add "traefik.http.services.dashboard.loadbalancer.server=http://tasks.checkin24hs_dashboard:80" \
      checkin24hs_dashboard
    
    echo "   ⏳ Esperando 15 segundos..."
    sleep 15
    
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com 2>&1)
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "   ✅ Dashboard funciona con tasks.checkin24hs_dashboard!"
    else
        echo "   ❌ Aún hay problemas (HTTP $HTTPS_CODE)"
    fi
fi

echo ""
echo "=== VERIFICACIÓN FINAL ==="
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10

echo ""
echo "=== LABELS ACTUALES ==="
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

echo ""






