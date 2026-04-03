#!/bin/bash

# Script para agregar etiquetas de Traefik al servicio WhatsApp
# Ejecutar desde el servidor

echo "=========================================="
echo "🔧 CONFIGURANDO TRAEFIK PARA WHATSAPP"
echo "=========================================="
echo ""

# Nombre del servicio (ajusta según tu configuración)
SERVICE_NAME="checkin24hs_whatsapp"

# Verificar que el servicio existe
echo "1️⃣ Verificando que el servicio existe..."
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: Servicio $SERVICE_NAME no encontrado"
    echo ""
    echo "Servicios disponibles:"
    docker service ls | grep -i whatsapp || echo "   No se encontraron servicios de WhatsApp"
    echo ""
    echo "Por favor, ajusta SERVICE_NAME en el script con el nombre correcto"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Verificar que está en la red easypanel
echo "2️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if ! echo "$NETWORKS" | grep -q "easypanel"; then
    echo "⚠️  Servicio no está en la red easypanel. Agregando..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 3
    echo "✅ Red easypanel agregada"
else
    echo "✅ Servicio ya está en la red easypanel"
fi
echo ""

# Remover etiquetas traefik existentes (opcional, para empezar limpio)
echo "3️⃣ Removiendo etiquetas Traefik existentes (si las hay)..."
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null | grep "^traefik" | while read label; do
    if [ -n "$label" ]; then
        echo "   Removiendo: $label"
        docker service update --label-rm "$label" "$SERVICE_NAME" 2>/dev/null
    fi
done
sleep 2
echo ""

# Agregar etiquetas Traefik
echo "4️⃣ Agregando etiquetas Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
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
echo "5️⃣ Verificando etiquetas aplicadas:"
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
echo "Nota: Puede tardar 1-2 minutos en que Traefik actualice la configuración"
echo ""
