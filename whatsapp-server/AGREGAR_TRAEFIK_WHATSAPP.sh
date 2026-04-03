#!/bin/bash

# Script para agregar etiquetas de Traefik al servicio WhatsApp
# Nombre del servicio: checkin24hs_whatsapp

echo "=========================================="
echo "🔧 CONFIGURANDO TRAEFIK PARA WHATSAPP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# Verificar que el servicio existe
echo "1️⃣ Verificando servicio..."
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: Servicio $SERVICE_NAME no encontrado"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Verificar que está en la red easypanel
echo "2️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if ! echo "$NETWORKS" | grep -q "easypanel"; then
    echo "⚠️  Agregando a red easypanel..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 3
    echo "✅ Red easypanel agregada"
else
    echo "✅ Ya está en la red easypanel"
fi
echo ""

# Agregar etiquetas Traefik (router + service vinculados; puerto 3001)
echo "3️⃣ Agregando etiquetas Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas agregadas correctamente"
else
    echo "❌ Error al agregar etiquetas"
    exit 1
fi

echo ""
echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

echo ""
echo "4️⃣ Verificando etiquetas aplicadas:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Ahora prueba acceder a:"
echo "  https://whatsapp.checkin24hs.com/api/health"
echo "  https://whatsapp.checkin24hs.com/api/qr"
echo ""
echo "Nota: Puede tardar 1-2 minutos en que Traefik actualice"
echo ""
