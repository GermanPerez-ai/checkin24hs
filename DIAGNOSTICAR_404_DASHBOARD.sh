#!/bin/bash
# Script para diagnosticar el error 404 en dashboard.checkin24hs.com

echo "🔍 DIAGNOSTICANDO ERROR 404 EN DASHBOARD"
echo "=========================================="
echo ""

# 1. Verificar si el servicio está corriendo
echo "1️⃣ Verificando si el servicio dashboard está corriendo..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
DASHBOARD_STATUS=$(docker service ps $DASHBOARD_SERVICE --no-trunc | head -2 | tail -1 | awk '{print $6}')
echo "   Estado: $DASHBOARD_STATUS"
echo ""

# 2. Verificar si el contenedor está respondiendo en el puerto 3000
echo "2️⃣ Verificando si el contenedor responde en el puerto 3000..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo "   Probando conexión interna al puerto 3000..."
docker exec "$CONTAINER_ID" wget -qO- http://localhost:3000/ 2>&1 | head -5 || echo "   ⚠️ No responde en localhost:3000"
echo ""

# 3. Verificar labels de Traefik
echo "3️⃣ Verificando labels de Traefik..."
docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
echo ""

TRAEFIK_ENABLED=$(docker service inspect $DASHBOARD_SERVICE --format '{{index .Spec.Labels "traefik.enable"}}')
if [ "$TRAEFIK_ENABLED" != "true" ]; then
    echo "❌ Traefik no está habilitado para este servicio"
    echo "   Necesitas agregar labels de Traefik"
else
    echo "✅ Traefik está habilitado"
fi
echo ""

# 4. Verificar red del servicio
echo "4️⃣ Verificando red del servicio..."
docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}'
echo ""

# 5. Verificar si Traefik está corriendo
echo "5️⃣ Verificando si Traefik está corriendo..."
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio Traefik"
else
    echo "✅ Traefik encontrado: $TRAEFIK_SERVICE"
    TRAEFIK_STATUS=$(docker service ps $TRAEFIK_SERVICE --no-trunc | head -2 | tail -1 | awk '{print $6}')
    echo "   Estado: $TRAEFIK_STATUS"
fi
echo ""

# 6. Verificar logs de Traefik para el dashboard
echo "6️⃣ Verificando logs de Traefik relacionados con dashboard..."
docker service logs $TRAEFIK_SERVICE --tail 50 2>&1 | grep -i dashboard | tail -10 || echo "   (No se encontraron logs relacionados con dashboard)"
echo ""

# 7. Resumen y solución
echo "=========================================="
echo "📋 RESUMEN Y SOLUCIÓN"
echo "=========================================="
echo ""

if [ "$TRAEFIK_ENABLED" != "true" ]; then
    echo "❌ PROBLEMA: Traefik no está habilitado para el servicio dashboard"
    echo ""
    echo "✅ SOLUCIÓN: Ejecuta este comando para agregar las labels de Traefik:"
    echo ""
    echo "docker service update \\"
    echo "  --label-add \"traefik.enable=true\" \\"
    echo "  --label-add \"traefik.http.routers.dashboard.rule=Host(\\\`dashboard.checkin24hs.com\\\`)\" \\"
    echo "  --label-add \"traefik.http.routers.dashboard.entrypoints=websecure\" \\"
    echo "  --label-add \"traefik.http.routers.dashboard.tls.certresolver=letsencrypt\" \\"
    echo "  --label-add \"traefik.http.routers.dashboard.tls=true\" \\"
    echo "  --label-add \"traefik.http.services.dashboard.loadbalancer.server.port=3000\" \\"
    echo "  --label-add \"traefik.docker.network=easypanel\" \\"
    echo "  $DASHBOARD_SERVICE"
    echo ""
    echo "Luego espera 30 segundos y reinicia Traefik:"
    echo "docker service update --force $TRAEFIK_SERVICE"
else
    echo "✅ Las labels de Traefik están configuradas"
    echo ""
    echo "Si aún ves 404, intenta:"
    echo "1. Reiniciar Traefik: docker service update --force $TRAEFIK_SERVICE"
    echo "2. Esperar 30 segundos"
    echo "3. Probar de nuevo: curl -I https://dashboard.checkin24hs.com"
fi
echo ""
