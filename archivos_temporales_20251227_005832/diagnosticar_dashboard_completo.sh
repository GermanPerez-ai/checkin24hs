#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO DEL DASHBOARD"
echo "=========================================="
echo ""

echo "1️⃣ Verificando red del servicio dashboard..."
echo "--------------------------------------------"
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}'
echo ""

echo "2️⃣ Verificando red de Traefik..."
echo "--------------------------------------------"
docker inspect $(docker ps | grep traefik | awk '{print $1}') --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}'
echo ""

echo "3️⃣ Obteniendo IP del servicio dashboard..."
echo "--------------------------------------------"
DASHBOARD_IP=$(docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}' | awk '{print $1}' | cut -d'/' -f1)
echo "IP: $DASHBOARD_IP"
echo ""

echo "4️⃣ Probando conexión desde Traefik con alias (guión):"
echo "--------------------------------------------"
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -5
echo ""

echo "5️⃣ Probando conexión desde Traefik con nombre servicio (guión bajo):"
echo "--------------------------------------------"
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs_dashboard:3000 2>&1 | head -5
echo ""

echo "6️⃣ Probando conexión desde Traefik con IP directa:"
echo "--------------------------------------------"
if [ ! -z "$DASHBOARD_IP" ]; then
    docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$DASHBOARD_IP:3000 2>&1 | head -5
else
    echo "❌ No se pudo obtener la IP del servicio"
fi
echo ""

echo "7️⃣ Verificando contenedores en la red easypanel:"
echo "--------------------------------------------"
docker network inspect easypanel --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -i dashboard || echo "❌ No se encontró el servicio dashboard en la red easypanel"
echo ""

echo "8️⃣ Verificando estado del servicio:"
echo "--------------------------------------------"
docker service ps checkin24hs_dashboard --no-trunc | head -3
echo ""

echo "9️⃣ Verificando logs del servicio:"
echo "--------------------------------------------"
docker service logs checkin24hs_dashboard --tail 5
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="

