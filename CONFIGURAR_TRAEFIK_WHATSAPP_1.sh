#!/bin/bash

echo "=========================================="
echo "🔧 CONFIGURANDO TRAEFIK PARA WHATSAPP 1"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ No se encontró el servicio: $SERVICE_NAME"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Remover todas las etiquetas traefik existentes
echo "1️⃣ Removiendo etiquetas existentes..."
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null | grep "^traefik" | while read label; do
    if [ -n "$label" ]; then
        echo "   Removiendo: $label"
        docker service update --label-rm "$label" "$SERVICE_NAME" 2>/dev/null
    fi
done

sleep 3

# Agregar las etiquetas esenciales
echo ""
echo "2️⃣ Agregando etiquetas de Traefik..."
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
  --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
  --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
  "$SERVICE_NAME" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas correctamente"
else
    echo "❌ Error agregando labels"
    exit 1
fi

echo ""
echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

echo ""
echo "3️⃣ Verificando labels aplicadas:"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep -E "traefik" | head -10

echo ""
echo "4️⃣ Probando endpoints:"
echo "   📊 /api/health:"
curl -s -k -w "\n   HTTP Status: %{http_code}\n" https://api1.checkin24hs.com/api/health 2>&1 | head -3

echo ""
echo "   📊 /api/status:"
curl -s -k -w "\n   HTTP Status: %{http_code}\n" https://api1.checkin24hs.com/api/status 2>&1 | head -3

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "Si ves HTTP Status: 200, ¡funcionó! ✅"
echo ""
