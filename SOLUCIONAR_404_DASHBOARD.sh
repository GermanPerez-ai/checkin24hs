#!/bin/bash

echo "🔧 SOLUCIONANDO 404 DEL DASHBOARD"
echo "=================================="
echo ""

# 1. Verificar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    echo "Listando todos los servicios:"
    docker service ls
    exit 1
fi

DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)
echo "✅ Servicio encontrado: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Verificar estado del servicio
echo "2️⃣ Verificando estado del servicio..."
docker service ps $DASHBOARD_SERVICE --no-trunc | head -3
echo ""

# 3. Verificar labels de Traefik
echo "3️⃣ Verificando labels de Traefik..."
TRAEFIK_LABELS=$(docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}')

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ NO hay labels de Traefik configuradas"
    echo ""
    echo "🔧 Agregando labels de Traefik..."
    
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
        --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
        --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
        $DASHBOARD_SERVICE
    
    echo "✅ Labels agregadas. Esperando 10 segundos..."
    sleep 10
    
    echo "Verificando labels después de agregar..."
    docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}'
else
    echo "✅ Labels de Traefik encontradas:"
    echo "$TRAEFIK_LABELS"
fi
echo ""

# 4. Verificar red del servicio
echo "4️⃣ Verificando red del servicio..."
SERVICE_NETWORK=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}')
echo "Red del servicio: $SERVICE_NETWORK"

# Verificar si está en la red de Traefik
TRAEFIK_NETWORK=$(docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>/dev/null)
if [ ! -z "$TRAEFIK_NETWORK" ]; then
    echo "Red de Traefik: $TRAEFIK_NETWORK"
    if [ "$SERVICE_NETWORK" != "$TRAEFIK_NETWORK" ]; then
        echo "⚠️ El servicio NO está en la misma red que Traefik"
        echo "Necesitas agregar el servicio a la red de Traefik"
    else
        echo "✅ El servicio está en la misma red que Traefik"
    fi
fi
echo ""

# 5. Verificar que el contenedor responde
echo "5️⃣ Verificando que el contenedor responde en puerto 3000..."
CONTAINER_ID=$(docker ps --filter "name=$DASHBOARD_NAME" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Probando conexión local..."
    docker exec $CONTAINER_ID wget -qO- http://localhost:3000 2>&1 | head -5 || echo "⚠️ No responde en localhost:3000"
else
    echo "⚠️ No se encontró contenedor activo"
fi
echo ""

# 6. Verificar logs de Traefik
echo "6️⃣ Verificando logs de Traefik (últimas 20 líneas relacionadas con dashboard)..."
docker service logs traefik --tail 100 2>&1 | grep -i "dashboard\|$DASHBOARD_NAME" | tail -20 || echo "No hay logs relacionados"
echo ""

# 7. Esperar y verificar
echo "7️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "✅ Diagnóstico completo"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Verifica que las labels de Traefik se agregaron correctamente"
echo "2. Espera 1-2 minutos para que Traefik detecte los cambios"
echo "3. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo ""
echo "Si aún no funciona, ejecuta:"
echo "  docker service logs traefik --tail 50"
echo "  docker service ps $DASHBOARD_SERVICE"
