#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔍 VERIFICAR HTTP Y AGREGAR WEBSECURE"
echo "=========================================="
echo ""

# Probar HTTP completo
echo "=== Probar HTTP (completo) ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
HTTP_SIZE=$(curl -s -o /dev/null -w "%{size_download}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
echo "HTTP Size: $HTTP_SIZE bytes"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "✅ HTTP funciona correctamente!"
else
    echo "⚠️  HTTP no funciona (status: $HTTP_STATUS)"
fi
echo ""

# Verificar labels actuales
echo "=== Labels actuales ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Agregar websecure (necesitamos AMBAS: web y websecure)
echo "=== Agregar label 'websecure' ==="
docker service update \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Label 'websecure' agregada"
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
echo "=== Labels después de agregar 'websecure' ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Verificar que tenemos ambas
echo "=== Verificar entrypoints ==="
ENTRYPOINTS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{if eq $key "traefik.http.routers.dashboard.entrypoints"}}{{$value}}{{"\n"}}{{end}}{{end}}')
echo "Entrypoints encontrados:"
echo "$ENTRYPOINTS"
echo ""

# Esperar más tiempo
echo "=== Esperando 20 segundos adicionales ==="
sleep 20
echo ""

# Probar ambos
echo "=== Probar HTTP ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
echo ""

echo "=== Probar HTTPS ==="
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Status: $HTTPS_STATUS"
if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "✅ HTTPS funciona correctamente!"
else
    echo "⚠️  HTTPS no funciona (status: $HTTPS_STATUS)"
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
