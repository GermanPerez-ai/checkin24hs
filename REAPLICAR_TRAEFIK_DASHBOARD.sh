#!/bin/bash
# Script para reaplicar labels de Traefik al dashboard después de reconstrucción

echo "🔧 REAPLICANDO LABELS DE TRAEFIK AL DASHBOARD"
echo "=========================================="
echo ""

# 1. Buscar servicios
echo "1️⃣ Buscando servicios..."
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio Traefik"
    docker service ls
    exit 1
fi

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

TRAEFIK_NAME=$(docker service ls | grep -i traefik | awk '{print $2}' | head -1)
DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

echo "✅ Traefik: $TRAEFIK_NAME ($TRAEFIK_SERVICE)"
echo "✅ Dashboard: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Verificar labels actuales
echo "2️⃣ Verificando labels actuales..."
docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
echo ""

# 3. Agregar labels de Traefik al dashboard
echo "3️⃣ Agregando labels de Traefik al dashboard..."
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
    --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard.tls=true" \
    --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
    --label-add "traefik.docker.network=easypanel" \
    $DASHBOARD_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas correctamente"
else
    echo "❌ Error al agregar labels"
    exit 1
fi
echo ""

# 4. Verificar labels después de agregar
echo "4️⃣ Verificando labels después de agregar..."
docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
echo ""

# 5. Reiniciar Traefik
echo "5️⃣ Reiniciando Traefik para que detecte los cambios..."
docker service update --force $TRAEFIK_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Traefik reiniciado"
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi
echo ""

# 6. Esperar a que Traefik se reinicie
echo "6️⃣ Esperando 30 segundos para que Traefik se reinicie..."
sleep 30
echo ""

# 7. Verificar estado de los servicios
echo "7️⃣ Verificando estado de los servicios..."
echo "   Dashboard:"
docker service ps $DASHBOARD_SERVICE --no-trunc | head -2
echo ""
echo "   Traefik:"
docker service ps $TRAEFIK_SERVICE --no-trunc | head -2
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Labels de Traefik reaplicadas al dashboard"
echo "   - Traefik reiniciado"
echo ""
echo "⏳ PRÓXIMOS PASOS:"
echo "   1. Espera 1-2 minutos más para que Traefik detecte completamente"
echo "   2. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo "   3. Si aún no funciona, verifica los logs:"
echo "      docker service logs $TRAEFIK_NAME --tail 50 | grep dashboard"
echo ""
