#!/bin/bash

echo "🔍 VERIFICANDO LABELS DE TRAEFIK"
echo "=================================="
echo ""

# Encontrar servicio dashboard
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)
DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Dashboard: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# Verificar labels de Traefik
echo "📋 Labels de Traefik en el servicio:"
echo "-----------------------------------"
docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if eq (index (split $key ".") 0) "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}' | grep traefik | sort

echo ""
echo "🔍 Verificando labels específicas:"
echo "-----------------------------------"

# Verificar cada label importante
LABELS=(
    "traefik.enable"
    "traefik.http.routers.dashboard.rule"
    "traefik.http.routers.dashboard.entrypoints"
    "traefik.http.routers.dashboard.tls.certresolver"
    "traefik.http.routers.dashboard.tls"
    "traefik.http.services.dashboard.loadbalancer.server.port"
    "traefik.docker.network"
)

for label in "${LABELS[@]}"; do
    VALUE=$(docker service inspect $DASHBOARD_SERVICE --format "{{index .Spec.Labels \"$label\"}}")
    if [ -z "$VALUE" ]; then
        echo "❌ $label: NO ENCONTRADA"
    else
        echo "✅ $label: $VALUE"
    fi
done

echo ""
echo "📊 Estado del servicio:"
echo "----------------------"
docker service ps $DASHBOARD_SERVICE --no-trunc | head -3

echo ""
echo "🌐 Estado de Traefik:"
echo "-------------------"
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    docker service ps $TRAEFIK_SERVICE --no-trunc | head -3
else
    echo "⚠️ No se encontró servicio Traefik"
fi

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "💡 Si todas las labels están presentes, el dashboard debería estar accesible en:"
echo "   https://dashboard.checkin24hs.com/"
echo ""
echo "⏳ Si aún no funciona, espera 1-2 minutos más para que Traefik detecte los cambios"
echo ""
