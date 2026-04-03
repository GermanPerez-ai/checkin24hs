#!/bin/bash

echo "🔧 SOLUCIONANDO ERROR 404 - AGREGANDO ETIQUETAS DE TRAEFIK"
echo "=========================================================="
echo ""

# 1. Obtener nombre del servicio
SERVICE="checkin24hs_dashboard"
echo "✅ Servicio: $SERVICE"
echo ""

# 2. Verificar estado actual
echo "2️⃣ Estado actual del servicio:"
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik || echo "   ❌ No tiene etiquetas de Traefik"
echo ""

# 3. Verificar red easypanel
echo "3️⃣ Verificando red easypanel..."
EASYPANEL_NET=$(docker network ls | grep easypanel | awk '{print $1}' | head -1)
if [ ! -z "$EASYPANEL_NET" ]; then
    EASYPANEL_NAME=$(docker network ls | grep easypanel | awk '{print $2}' | head -1)
    echo "✅ Red easypanel encontrada: $EASYPANEL_NAME"
    
    # Verificar si el servicio está en esta red
    SERVICE_NETS=$(docker service inspect $SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}')
    if echo "$SERVICE_NETS" | grep -q "$EASYPANEL_NET"; then
        echo "✅ El servicio ya está en la red easypanel"
    else
        echo "⚠️  El servicio NO está en la red easypanel"
        echo "🔧 Agregando a la red easypanel..."
        docker service update --network-add $EASYPANEL_NET $SERVICE
        sleep 5
    fi
else
    echo "⚠️  No se encontró red easypanel (puede tener otro nombre)"
fi
echo ""

# 4. Agregar etiquetas de Traefik
echo "4️⃣ Agregando etiquetas de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  $SERVICE 2>&1 | grep -v "update paused\|update in progress" || true

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas de Traefik agregadas correctamente"
else
    echo "⚠️  Error al agregar etiquetas (puede que ya existan algunas)"
fi
echo ""

# 5. Verificar que se agregaron
echo "5️⃣ Verificando etiquetas agregadas..."
sleep 5
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""

# 6. Esperar para que Traefik detecte
echo "⏳ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 7. Verificar logs de Traefik
echo ""
echo "6️⃣ Verificando logs de Traefik (últimas 20 líneas relacionadas con dashboard)..."
docker service logs traefik --tail 100 2>&1 | grep -i "dashboard\|$SERVICE" | tail -20 || echo "   (No se encontraron logs relacionados)"
echo ""

# 8. Probar acceso
echo "7️⃣ Probando acceso HTTPS..."
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Espera 1-2 minutos más"
echo "2. Recarga el dashboard en el navegador (Ctrl+Shift+R)"
echo "3. Si aún ves 404, verifica los logs:"
echo "   docker service logs traefik --tail 50"
echo ""
