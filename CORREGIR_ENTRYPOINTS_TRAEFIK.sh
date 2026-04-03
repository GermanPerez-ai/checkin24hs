#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔧 CORREGIR ENTRYPOINTS DE TRAEFIK"
echo "=========================================="
echo ""

# Eliminar las labels de entrypoints actuales (puede haber web o websecure)
echo "=== 1. Eliminar labels de entrypoints actuales ==="
docker service update \
  --label-rm "traefik.http.routers.dashboard.entrypoints" \
  "$SERVICE_NAME" 2>/dev/null || true

echo "Esperando 5 segundos..."
sleep 5
echo ""

# Agregar la label correcta con AMBOS entrypoints separados por comas
echo "=== 2. Agregar label con AMBOS entrypoints (web,websecure) ==="
docker service update \
  --label-add "traefik.http.routers.dashboard.entrypoints=web,websecure" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Label con ambos entrypoints agregada"
else
    echo "❌ Error al agregar label"
    exit 1
fi
echo ""

# Esperar actualización
echo "=== 3. Esperando 10 segundos ==="
sleep 10
echo ""

# Verificar todas las labels
echo "=== 4. Verificar todas las labels ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Verificar entrypoints específicamente
echo "=== 5. Verificar entrypoints ==="
ENTRYPOINTS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{if eq $key "traefik.http.routers.dashboard.entrypoints"}}{{$value}}{{end}}{{end}}')
echo "Entrypoints configurados: $ENTRYPOINTS"
if echo "$ENTRYPOINTS" | grep -q "web" && echo "$ENTRYPOINTS" | grep -q "websecure"; then
    echo "✅ Ambos entrypoints están configurados"
else
    echo "⚠️  Falta algún entrypoint"
fi
echo ""

# Esperar más tiempo para Traefik
echo "=== 6. Esperando 20 segundos adicionales para Traefik ==="
sleep 20
echo ""

# Probar ambos
echo "=== 7. Probar acceso ==="
echo "HTTP:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "  Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "  ✅ HTTP funciona!"
else
    echo "  ⚠️  HTTP no funciona"
fi
echo ""

echo "HTTPS:"
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "  Status: $HTTPS_STATUS"
if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "  ✅ HTTPS funciona!"
else
    echo "  ⚠️  HTTPS no funciona"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
