#!/bin/bash

echo "🔍 VERIFICANDO LABELS DE TRAEFIK"
echo "=================================="
echo ""

# Encontrar servicio dashboard
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "📋 Labels de Traefik del servicio dashboard:"
echo ""

# Ver todas las labels y filtrar las de Traefik
docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.Labels}}' | python3 -m json.tool 2>/dev/null | grep -i traefik || docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.Labels}}' | grep -i traefik

echo ""
echo "✅ Verificación completada"
