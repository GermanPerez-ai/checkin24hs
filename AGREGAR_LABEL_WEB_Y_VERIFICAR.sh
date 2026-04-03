#!/bin/bash
# Agregar label faltante 'web' y verificar

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔧 AGREGAR LABEL 'web' FALTANTE"
echo "=========================================="
echo ""

# Verificar labels actuales
echo "=== Labels actuales ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Agregar label 'web' entrypoint
echo "=== Agregar label 'web' entrypoint ==="
docker service update \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Label 'web' agregada"
else
    echo "❌ Error al agregar label"
    exit 1
fi
echo ""

# Esperar actualización
echo "=== Esperando 10 segundos ==="
sleep 10
echo ""

# Verificar labels después
echo "=== Labels después de agregar 'web' ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Verificar Traefik
echo "=== Verificar Traefik ==="
TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "✅ Traefik servicio: $TRAEFIK_SERVICE"
    echo ""
    echo "=== Últimos logs de Traefik (buscando 'dashboard') ==="
    docker service logs "$TRAEFIK_SERVICE" --tail 50 2>&1 | grep -i "dashboard\|checkin24hs" | tail -10 || echo "(no hay logs relevantes)"
else
    echo "⚠️  Traefik no encontrado como servicio"
fi
echo ""

# Esperar más tiempo
echo "=== Esperando 20 segundos adicionales para Traefik ==="
sleep 20
echo ""

# Probar acceso
echo "=== Probar acceso HTTP ==="
HTTP_RESPONSE=$(curl -I http://$DOMAIN 2>&1 | head -3)
echo "$HTTP_RESPONSE"
echo ""

echo "=== Probar acceso HTTPS ==="
HTTPS_RESPONSE=$(curl -I https://$DOMAIN 2>&1 | head -3)
echo "$HTTPS_RESPONSE"
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
