#!/bin/bash

echo "🔍 DIAGNÓSTICO Y SOLUCIÓN DE ERROR 404"
echo "======================================"
echo ""

# 1. Verificar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    echo "📋 Servicios disponibles:"
    docker service ls
    exit 1
fi

echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
echo ""

# 2. Verificar estado del servicio
echo "2️⃣ Verificando estado del servicio dashboard..."
docker service ps $DASHBOARD_SERVICE --no-trunc | head -5
echo ""

# 3. Verificar etiquetas de Traefik
echo "3️⃣ Verificando etiquetas de Traefik del servicio..."
TRAEFIK_LABELS=$(docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}')

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ No se encontraron etiquetas de Traefik"
    echo "🔧 Agregando etiquetas de Traefik..."
    
    # Obtener el puerto del servicio
    PORT=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null || echo "3000")
    if [ -z "$PORT" ] || [ "$PORT" = "0" ]; then
        PORT="3000"
    fi
    
    echo "   Puerto detectado: $PORT"
    
    # Agregar etiquetas de Traefik
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
        --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
        --label-add "traefik.http.routers.dashboard.tls=true" \
        --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.dashboard.loadbalancer.server.port=$PORT" \
        $DASHBOARD_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true
    
    echo "✅ Etiquetas agregadas"
    sleep 5
else
    echo "✅ Etiquetas encontradas:"
    echo "$TRAEFIK_LABELS" | head -10
fi
echo ""

# 4. Verificar red
echo "4️⃣ Verificando red del servicio..."
SERVICE_NETWORKS=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}')
echo "Redes del servicio:"
for NET in $SERVICE_NETWORKS; do
    NET_NAME=$(docker network inspect $NET --format '{{.Name}}' 2>/dev/null || echo "ID: $NET")
    echo "  - $NET_NAME"
done
echo ""

# Verificar si está en la red easypanel
EASYPANEL_NET=$(docker network ls | grep easypanel | awk '{print $1}' | head -1)
if [ ! -z "$EASYPANEL_NET" ]; then
    if echo "$SERVICE_NETWORKS" | grep -q "$EASYPANEL_NET"; then
        echo "✅ El servicio está en la red easypanel"
    else
        echo "⚠️  El servicio NO está en la red easypanel"
        echo "🔧 Agregando a la red easypanel..."
        docker service update --network-add $EASYPANEL_NET $DASHBOARD_SERVICE
        sleep 5
    fi
fi
echo ""

# 5. Verificar logs de Traefik
echo "5️⃣ Verificando logs de Traefik relacionados con dashboard..."
docker service logs traefik --tail 100 2>&1 | grep -i "dashboard\|404\|error" | tail -15
echo ""

# 6. Verificar conectividad desde Traefik
echo "6️⃣ Verificando conectividad desde Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    
    # Intentar hacer ping al servicio
    SERVICE_TASK=$(docker service ps $DASHBOARD_SERVICE --format "{{.Name}}" --no-trunc | head -1)
    if [ ! -z "$SERVICE_TASK" ]; then
        echo "Intentando conectar a: tasks.$DASHBOARD_SERVICE"
        docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 "http://tasks.$DASHBOARD_SERVICE:$PORT/" 2>&1 | head -5 || echo "   ⚠️  No se pudo conectar"
    fi
fi
echo ""

# 7. Verificar puerto del servicio
echo "7️⃣ Verificando puerto del servicio..."
SERVICE_PORTS=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Endpoint.Ports}}{{.Protocol}}/{{.TargetPort}}->{{.PublishedPort}}{{end}}')
echo "Puertos del servicio: $SERVICE_PORTS"
echo ""

# 8. Resumen y recomendaciones
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Servicio: $DASHBOARD_SERVICE"
echo "Puerto: $PORT"
echo ""

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "✅ Etiquetas de Traefik agregadas"
else
    echo "✅ Etiquetas de Traefik ya existían"
fi

echo ""
echo "⏳ Espera 30-60 segundos para que Traefik detecte los cambios"
echo "Luego prueba acceder a: https://dashboard.checkin24hs.com"
echo ""
echo "🔍 Para ver logs en tiempo real:"
echo "   docker service logs traefik -f"
echo ""
