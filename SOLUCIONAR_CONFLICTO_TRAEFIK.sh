#!/bin/bash

echo "=========================================="
echo "🔧 SOLUCIONANDO CONFLICTO DE TRAEFIK"
echo "=========================================="
echo ""

# Ver todos los servicios de WhatsApp
echo "1️⃣ Servicios de WhatsApp:"
echo "=========================================="
docker service ls | grep whatsapp
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# Ver etiquetas actuales
echo "2️⃣ Etiquetas actuales del servicio:"
echo "=========================================="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort
echo ""

# Remover todas las etiquetas de Traefik existentes para empezar limpio
echo "3️⃣ Removiendo etiquetas de Traefik existentes..."
echo "=========================================="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' | grep "^traefik" | while read label; do
    echo "Removiendo: $label"
    docker service update --label-rm "$label" "$SERVICE_NAME" > /dev/null 2>&1
done
echo ""

sleep 3

# Agregar etiquetas correctas con nombre de servicio explícito
echo "4️⃣ Agregando etiquetas correctas..."
echo "=========================================="
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
  --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
  --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
  --label-add 'traefik.http.middlewares.whatsapp-cors.headers.accessControlAllowMethods=GET,POST,OPTIONS' \
  --label-add 'traefik.http.middlewares.whatsapp-cors.headers.accessControlAllowOrigin=*' \
  --label-add 'traefik.http.middlewares.whatsapp-cors.headers.accessControlAllowHeaders=Content-Type,Authorization,Accept' \
  --label-add 'traefik.http.routers.whatsapp-api1.middlewares=whatsapp-cors' \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Etiquetas agregadas correctamente"
    echo ""
    echo "Esperando 10 segundos para que Traefik detecte los cambios..."
    sleep 10
    
    echo ""
    echo "5️⃣ Verificando configuración:"
    echo "=========================================="
    docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort
    
    echo ""
    echo "6️⃣ Verificando logs de Traefik:"
    echo "=========================================="
    TRAEFIK=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
    docker logs "$TRAEFIK" --tail 10 2>&1 | grep -i "api1\|whatsapp\|error" | tail -5
    
    echo ""
    echo "7️⃣ Probando conexión:"
    echo "=========================================="
    curl -I https://api1.checkin24hs.com/api/status?card=1 2>&1 | head -5
    
    echo ""
    echo "=========================================="
    echo "📋 RESULTADO:"
    echo "=========================================="
    echo ""
    echo "Si ves HTTP/2 200 o 200 OK, ¡funcionó! ✅"
    echo "Si ves HTTP/2 404, espera unos segundos más y vuelve a probar"
    echo ""
else
    echo ""
    echo "❌ Error al agregar etiquetas"
fi



