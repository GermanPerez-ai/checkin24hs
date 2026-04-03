#!/bin/bash
# Configurar Traefik para whatsapp1.checkin24hs.com

echo "=== Configurar Traefik para whatsapp1.checkin24hs.com ==="
echo ""

# 1. Buscar el servicio de WhatsApp
echo "1️⃣ Buscando servicio de WhatsApp..."
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "whatsapp|3001" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio de WhatsApp"
    echo ""
    echo "Por favor, crea el servicio primero en EasyPanel:"
    echo "  - Nombre: whatsapp1"
    echo "  - Puerto: 3001"
    echo "  - Ruta: /whatsapp-server"
    echo ""
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Verificar que está corriendo
echo "2️⃣ Verificando estado del servicio..."
SERVICE_STATUS=$(docker service ps $SERVICE_NAME --format "{{.CurrentState}}" | head -1)
if [ "$SERVICE_STATUS" != "Running" ]; then
    echo "⚠️  Servicio no está corriendo. Estado: $SERVICE_STATUS"
    echo "   Esperando a que inicie..."
    sleep 10
fi
echo ""

# 3. Verificar que está en la red easypanel
echo "3️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "✅ Servicio ya está en la red easypanel"
else
    echo "⚠️  Servicio NO está en la red easypanel, agregándolo..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 5
fi
echo ""

# 4. Configurar etiquetas Traefik
echo "4️⃣ Configurando etiquetas Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik agregadas correctamente"
else
    echo "❌ Error al agregar etiquetas Traefik"
    exit 1
fi
echo ""

# 5. Verificar configuración
echo "5️⃣ Verificando configuración aplicada..."
docker service inspect $SERVICE_NAME --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik
echo ""

# 6. Esperar a que Traefik detecte los cambios
echo "6️⃣ Esperando a que Traefik detecte los cambios..."
sleep 10

# 7. Verificar logs de Traefik
echo "7️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 30 2>&1 | grep -iE "whatsapp1|3001" | tail -5 || echo "   No hay referencias aún en los logs"
echo ""

# 8. Verificar DNS
echo "8️⃣ Verificando DNS..."
DNS_RESULT=$(nslookup whatsapp1.checkin24hs.com 2>&1 | grep -A 2 "Name:" | tail -1)
if echo "$DNS_RESULT" | grep -q "72.61.58.240"; then
    echo "✅ DNS configurado correctamente"
else
    echo "⚠️  DNS NO configurado"
    echo "   Necesitas agregar registro A: whatsapp1.checkin24hs.com → 72.61.58.240"
fi
echo ""

echo "=== CONFIGURACIÓN COMPLETADA ==="
echo ""
echo "✅ Traefik configurado para whatsapp1.checkin24hs.com"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Configurar DNS (si no está configurado)"
echo "   2. Esperar propagación DNS (puede tardar hasta 24 horas)"
echo "   3. Esperar generación de certificado SSL (puede tardar unos minutos)"
echo "   4. Probar: curl -I https://whatsapp1.checkin24hs.com"
echo ""


















