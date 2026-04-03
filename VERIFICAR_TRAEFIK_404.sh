#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR TRAEFIK Y ACCESO"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

# 1. Verificar acceso directo al contenedor
echo "=== 1. ACCESO DIRECTO AL CONTENEDOR ==="
CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
echo "IP del contenedor: $CONTAINER_IP"
echo ""
echo "Probando conexión directa:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$CONTAINER_IP:3000" 2>/dev/null || echo "No se pudo conectar directamente"
echo ""

# 2. Verificar Traefik
echo "=== 2. VERIFICAR TRAEFIK ==="
docker ps --filter "name=traefik" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 3. Verificar labels del servicio (para Traefik)
echo "=== 3. LABELS DEL SERVICIO (para Traefik) ==="
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep -i "traefik\|router\|rule" | head -10
echo ""

# 4. Verificar logs de Traefik
echo "=== 4. LOGS DE TRAEFIK (últimas 20 líneas) ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs "$TRAEFIK_CONTAINER" --tail 20 2>&1 | tail -20
else
    echo "No se encontró contenedor de Traefik"
fi
echo ""

# 5. Verificar red del contenedor
echo "=== 5. RED DEL CONTENEDOR ==="
docker inspect "$CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
