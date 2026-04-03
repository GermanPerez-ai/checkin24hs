#!/bin/bash
# Script para verificar después del deploy final

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR DESPUES DE DEPLOY FINAL"
echo "=========================================="
echo ""

echo "=== 1. Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor"
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 2. Verificar Build Number ==="
BUILD_NUMBER=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrado")
VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrado")
echo "Version: $VERSION"
echo "Build Number: #$BUILD_NUMBER"
if [ "$BUILD_NUMBER" = "5" ]; then
    echo "✅ OK: Build Number correcto (#5)"
else
    echo "❌ ERROR: Build Number incorrecto (esperado: #5, encontrado: #$BUILD_NUMBER)"
    echo ""
    echo "PROBLEMA: Docker uso caché para dashboard.html"
    echo "SOLUCION: Necesitamos forzar rebuild sin caché"
fi
echo ""

echo "=== 3. Verificar Display de Versión ==="
if docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "✅ OK: Display de versión encontrado"
else
    echo "❌ ERROR: Display de versión NO encontrado"
fi
echo ""

echo "=== 4. Verificar desde HTTP ==="
sleep 2
HTTP_BUILD=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
echo ""

echo "=== 5. Verificar labels de Traefik ==="
TRAEFIK_COUNT=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep -c traefik || echo "0")
if [ "$TRAEFIK_COUNT" -gt 0 ]; then
    echo "✅ OK: Labels de Traefik encontradas ($TRAEFIK_COUNT labels)"
else
    echo "⚠️ ADVERTENCIA: No se encontraron labels de Traefik"
fi
echo ""

echo "=========================================="
if [ "$BUILD_NUMBER" = "5" ] && docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "✅ DEPLOY EXITOSO"
    echo ""
    echo "El display de versión debería aparecer en el sidebar."
else
    echo "❌ DEPLOY INCOMPLETO - Docker uso caché"
    echo ""
    echo "SOLUCION: Forzar rebuild sin caché en EasyPanel"
    echo "O cambiar algo en dashboard.html para invalidar caché"
fi
echo "=========================================="
echo ""
