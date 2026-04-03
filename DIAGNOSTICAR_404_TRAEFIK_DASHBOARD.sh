#!/bin/bash
# Diagnosticar problema 404 de Traefik para dashboard

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔍 DIAGNÓSTICO 404 TRAEFIK DASHBOARD"
echo "=========================================="
echo ""

echo "=== 1. Verificar que el servicio existe ==="
docker service ls | grep "$SERVICE_NAME"
if [ $? -ne 0 ]; then
    echo "❌ Servicio no encontrado"
    exit 1
fi
echo "✅ Servicio encontrado"
echo ""

echo "=== 2. Verificar estado del servicio ==="
docker service ps "$SERVICE_NAME" --no-trunc | head -5
echo ""

echo "=== 3. Verificar labels de Traefik ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== 4. Verificar puerto del servicio ==="
docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.PublishedPort}} -> {{.TargetPort}} ({{.Protocol}}){{"\n"}}{{end}}'
echo ""

echo "=== 5. Verificar red del servicio ==="
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.Networks}}{{.Target}}{"\n"}}{{end}}'
echo ""

echo "=== 6. Verificar logs recientes del servicio ==="
docker service logs "$SERVICE_NAME" --tail 20 2>&1 | tail -10
echo ""

echo "=== 7. Probar acceso directo al servicio (desde contenedor) ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    docker exec "$CONTAINER" wget -q -O- http://localhost:3000 2>&1 | head -5 || echo "No se pudo acceder al contenedor"
else
    echo "⚠️  No se encontró contenedor activo"
fi
echo ""

echo "=== 8. Verificar configuración de Traefik ==="
docker service ls | grep traefik
echo ""

echo "=== 9. Probar HTTP ==="
curl -I http://$DOMAIN 2>&1 | head -10
echo ""

echo "=== 10. Probar HTTPS ==="
curl -I https://$DOMAIN 2>&1 | head -10
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
