#!/bin/bash

# Script completo para aplicar configuración de Traefik al servicio WhatsApp

echo "=========================================="
echo "🔧 APLICANDO CONFIGURACIÓN TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar que el servicio existe
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: Servicio $SERVICE_NAME no encontrado"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Verificar red easypanel
echo "1️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if ! echo "$NETWORKS" | grep -q "easypanel"; then
    echo "   ➕ Agregando a red easypanel..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 3
    echo "   ✅ Red easypanel agregada"
else
    echo "   ✅ Ya está en red easypanel"
fi
echo ""

# 3. Aplicar etiquetas de Traefik
echo "2️⃣ Aplicando etiquetas de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Etiquetas aplicadas correctamente"
else
    echo "   ❌ Error al aplicar etiquetas"
    exit 1
fi

echo ""
echo "⏳ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 4. Verificar etiquetas aplicadas
echo ""
echo "3️⃣ Verificando etiquetas aplicadas:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Ahora prueba:"
echo "  curl -I https://whatsapp.checkin24hs.com/api/qr"
echo "  curl -I https://whatsapp.checkin24hs.com/qr"
echo ""
