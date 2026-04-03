#!/bin/bash

echo "=========================================="
echo "🔧 CONFIGURANDO TRAEFIK (SIN CORS - El servidor lo maneja)"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# Remover todas las etiquetas traefik
echo "1️⃣ Removiendo etiquetas existentes..."
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' | grep "^traefik" | while read label; do
    docker service update --label-rm "$label" "$SERVICE_NAME" 2>/dev/null
done

sleep 5

# Agregar solo las etiquetas esenciales (sin CORS - el servidor lo maneja)
echo ""
echo "2️⃣ Agregando etiquetas esenciales..."
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
  --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
  --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
  "$SERVICE_NAME"

echo ""
echo "✅ Configuración aplicada"
echo ""
echo "Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

echo ""
echo "3️⃣ Verificando logs de Traefik:"
TRAEFIK=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
docker logs "$TRAEFIK" --tail 15 2>&1 | grep -i "api1\|whatsapp\|error" | tail -5

echo ""
echo "4️⃣ Probando conexión:"
curl -I https://api1.checkin24hs.com/api/status?card=1

echo ""
echo "5️⃣ Probando con curl completo (para ver respuesta):"
curl -s https://api1.checkin24hs.com/api/status?card=1 | head -3

echo ""
echo "=========================================="
echo "📋 RESULTADO:"
echo "=========================================="
echo ""
echo "Si ves HTTP/2 200 o una respuesta JSON, ¡funcionó! ✅"
echo "El servidor ya tiene CORS configurado, no necesitamos middleware de Traefik"
echo ""



