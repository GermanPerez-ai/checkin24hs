#!/bin/bash
# Verificar labels y probar acceso

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔍 VERIFICACIÓN FINAL"
echo "=========================================="
echo ""

# Verificar todas las labels de Traefik
echo "=== Labels de Traefik ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Verificar que Traefik está corriendo
echo "=== Traefik ==="
if docker service ls | grep -qi "traefik"; then
    TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
    echo "✅ Traefik está corriendo: $TRAEFIK_SERVICE"
else
    echo "⚠️  Traefik no está corriendo como servicio"
fi
echo ""

# Esperar un poco más para que Traefik detecte
echo "=== Esperando 15 segundos para que Traefik detecte el cambio ==="
sleep 15
echo ""

# Probar acceso HTTP
echo "=== Probar acceso HTTP ==="
echo "curl -I http://$DOMAIN"
curl -I http://$DOMAIN 2>&1 | head -10
echo ""

# Probar acceso HTTPS
echo "=== Probar acceso HTTPS ==="
echo "curl -I https://$DOMAIN"
curl -I https://$DOMAIN 2>&1 | head -10
echo ""

# Si hay problemas, mostrar logs de Traefik
if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "=== Últimas 20 líneas de logs de Traefik ==="
    docker service logs "$TRAEFIK_SERVICE" --tail 20 2>&1 | grep -i "dashboard\|checkin24hs\|error" || echo "(no hay logs relevantes)"
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
