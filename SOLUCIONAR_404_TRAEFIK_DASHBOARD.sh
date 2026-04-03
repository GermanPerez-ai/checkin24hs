#!/bin/bash
# Solucionar 404 de Traefik para dashboard

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "🔧 SOLUCIONAR 404 TRAEFIK DASHBOARD"
echo "=========================================="
echo ""

echo "=== Paso 1: Verificar servicio ==="
docker service ls | grep "$SERVICE_NAME"
if [ $? -ne 0 ]; then
    echo "❌ Servicio no encontrado. Debe crearse primero en EasyPanel."
    exit 1
fi
echo "✅ Servicio encontrado"
echo ""

echo "=== Paso 2: Agregar labels de Traefik ==="

# Eliminar labels antiguas si existen
echo "   Eliminando labels antiguas..."
docker service update --label-rm "traefik.enable" "$SERVICE_NAME" 2>/dev/null || true
docker service update --label-rm "traefik.http.routers.dashboard.rule" "$SERVICE_NAME" 2>/dev/null || true
docker service update --label-rm "traefik.http.routers.dashboard.entrypoints" "$SERVICE_NAME" 2>/dev/null || true
docker service update --label-rm "traefik.http.routers.dashboard.service" "$SERVICE_NAME" 2>/dev/null || true
docker service update --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" "$SERVICE_NAME" 2>/dev/null || true
sleep 3

# Agregar labels correctas
echo "   Agregando labels de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web,websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas"
else
    echo "❌ Error al agregar labels"
    exit 1
fi
echo ""

echo "=== Paso 3: Agregar router HTTPS con TLS ==="
docker service update \
  --label-add "traefik.http.routers.dashboard-https.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard-https.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-https.service=dashboard" \
  --label-add "traefik.http.routers.dashboard-https.tls=true" \
  --label-add "traefik.http.routers.dashboard-https.tls.certresolver=letsencrypt" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Router HTTPS agregado"
else
    echo "⚠️  Error al agregar router HTTPS (puede que ya exista)"
fi
echo ""

echo "=== Paso 4: Verificar labels aplicadas ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== Paso 5: Esperar 15 segundos para que Traefik actualice ==="
sleep 15
echo ""

echo "=== Paso 6: Probar HTTP ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
echo "HTTP Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "✅ HTTP funciona!"
elif [ "$HTTP_STATUS" = "404" ]; then
    echo "⚠️  HTTP aún da 404. Esperando más tiempo..."
    sleep 20
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
    echo "HTTP Status después de esperar: $HTTP_STATUS"
else
    echo "⚠️  HTTP Status: $HTTP_STATUS"
fi
echo ""

echo "=== Paso 7: Probar HTTPS ==="
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
echo "HTTPS Status: $HTTPS_STATUS"
if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "✅ HTTPS funciona!"
elif [ "$HTTPS_STATUS" = "404" ]; then
    echo "⚠️  HTTPS aún da 404. Let's Encrypt puede estar generando el certificado."
    echo "   Espera 1-2 minutos y prueba de nuevo."
else
    echo "⚠️  HTTPS Status: $HTTPS_STATUS"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "📋 Si aún da 404:"
echo "1. Verifica que el servicio esté corriendo: docker service ps $SERVICE_NAME"
echo "2. Verifica los logs: docker service logs $SERVICE_NAME --tail 50"
echo "3. Espera 1-2 minutos y recarga la página con Ctrl+F5"
echo ""
