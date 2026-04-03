#!/bin/bash
# Corregir etiquetas de Traefik después de reiniciar el contenedor de WhatsApp

echo "=== Corrigiendo configuración de Traefik para WhatsApp ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: Servicio $SERVICE_NAME no encontrado"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Remover todas las etiquetas traefik existentes
echo "=== Removiendo etiquetas Traefik existentes ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' | grep "^traefik" | while read label; do
    echo "  Removiendo: $label"
    docker service update --label-rm "$label" "$SERVICE_NAME" 2>/dev/null
done

echo ""
echo "Esperando 5 segundos..."
sleep 5

# 3. Agregar etiquetas Traefik correctas
echo "=== Agregando etiquetas Traefik correctas ==="
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
  --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
  --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-api1-service' \
  --label-add 'traefik.http.services.whatsapp-api1-service.loadbalancer.server.port=3001' \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas agregadas correctamente"
else
    echo "❌ Error al agregar etiquetas"
    exit 1
fi

echo ""
echo "Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

# 4. Verificar configuración
echo ""
echo "=== Verificando configuración ==="
echo "Etiquetas Traefik del servicio:"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort

echo ""
echo "=== Verificando logs de Traefik ==="
TRAEFIK=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK" ]; then
    echo "Contenedor Traefik: $TRAEFIK"
    echo "Últimas líneas relacionadas con api1/whatsapp:"
    docker logs "$TRAEFIK" --tail 20 | grep -i "api1\|whatsapp" || echo "No hay logs recientes relacionados"
else
    echo "⚠️ Contenedor Traefik no encontrado"
fi

echo ""
echo "=== Probando endpoint ==="
echo "Probando: https://api1.checkin24hs.com/api/status?card=1"
curl -I https://api1.checkin24hs.com/api/status?card=1 2>&1 | head -10

echo ""
echo "=== Probando respuesta completa ==="
curl -s https://api1.checkin24hs.com/api/status?card=1 | head -5

echo ""
echo "✅ Proceso completado"
echo ""
echo "Si aún hay errores 502, espera 30 segundos más y vuelve a probar."
echo "Traefik puede tardar en detectar los cambios después de un reinicio."



