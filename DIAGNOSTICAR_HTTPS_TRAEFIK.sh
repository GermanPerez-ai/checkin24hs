#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE HTTPS"
echo "=========================================="
echo ""

# Verificar Traefik
TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ Traefik no encontrado como servicio"
    exit 1
fi

echo "Traefik servicio: $TRAEFIK_SERVICE"
echo ""

# Ver logs de Traefik buscando errores o información sobre el dashboard
echo "=== Logs de Traefik (últimas 50 líneas) ==="
docker service logs "$TRAEFIK_SERVICE" --tail 50 2>&1 | tail -20
echo ""

# Buscar específicamente errores o warnings sobre el dashboard
echo "=== Buscar errores/warnings sobre dashboard ==="
docker service logs "$TRAEFIK_SERVICE" --tail 200 2>&1 | grep -i "dashboard\|checkin24hs\|error\|warn" | tail -10 || echo "(no hay errores relevantes)"
echo ""

# Verificar configuración de Traefik (si es posible)
echo "=== Verificar configuración de Traefik ==="
echo "Verificando si Traefik tiene configuración de TLS/SSL..."
docker service inspect "$TRAEFIK_SERVICE" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -i "tls\|ssl\|cert" | head -5 || echo "(no hay configuración TLS visible)"
echo ""

# Verificar si necesitamos un router separado para HTTPS
echo "=== Verificar labels del servicio dashboard ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Probar acceso directo al servicio (sin Traefik)
echo "=== Probar acceso directo al servicio ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        echo "IP del contenedor: $CONTAINER_IP"
        echo "Probando acceso directo al puerto 3000:"
        curl -s -o /dev/null -w "Status: %{http_code}\n" http://$CONTAINER_IP:3000 || echo "No se pudo conectar"
    fi
fi
echo ""

# Sugerencia: Agregar router separado para HTTPS con TLS
echo "=== SUGERENCIA ==="
echo "Puede que necesitemos agregar un router separado para HTTPS con TLS."
echo "O verificar que Traefik tenga configuración de certificados SSL."
echo ""
