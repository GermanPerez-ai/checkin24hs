#!/bin/bash

echo "=========================================="
echo "🔧 CORRIGIENDO CONFIGURACIÓN DE TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Ver todas las etiquetas actuales
echo "1️⃣ Etiquetas actuales de Traefik:"
echo "=========================================="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort
echo ""

# 2. Remover todas las etiquetas traefik existentes
echo "2️⃣ Removiendo etiquetas existentes..."
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' | grep "^traefik" | while read label; do
    echo "  Removiendo: $label"
    docker service update --label-rm "$label" "$SERVICE_NAME" 2>/dev/null
done

echo ""
echo "Esperando 5 segundos..."
sleep 5

# 3. Agregar etiquetas correctas con nombre único de router y servicio explícito
echo ""
echo "3️⃣ Agregando etiquetas correctas..."
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
  --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-api1-service' \
  --label-add 'traefik.http.services.whatsapp-api1-service.loadbalancer.server.port=3001' \
  "$SERVICE_NAME"

echo ""
echo "✅ Configuración aplicada"
echo ""
echo "Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

# 4. Verificar logs de Traefik
echo ""
echo "4️⃣ Verificando logs de Traefik:"
TRAEFIK=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
docker logs "$TRAEFIK" --tail 10 2>&1 | grep -i "api1\|whatsapp\|error" | tail -5

# 5. Probar conexión
echo ""
echo "5️⃣ Probando conexión:"
curl -I https://api1.checkin24hs.com/api/status?card=1

echo ""
echo "6️⃣ Probando con respuesta completa:"
curl -s https://api1.checkin24hs.com/api/status?card=1 | head -3

echo ""
echo "=========================================="
echo "📋 RESULTADO:"
echo "=========================================="
echo ""
echo "Si ves HTTP/2 200, ¡funcionó! ✅"
echo "Si ves 502, espera unos segundos más y vuelve a probar"
echo ""



