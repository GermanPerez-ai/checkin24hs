#!/bin/bash
# Verificar y aplicar etiquetas Traefik de forma persistente

echo "=========================================="
echo "🔍 Verificando y aplicando etiquetas Traefik"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando etiquetas actuales del servicio..."
echo ""
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "❌ No hay etiquetas Traefik en el servicio"

echo ""
echo "2️⃣ Verificando etiquetas en los contenedores..."
CONTAINERS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")
for container in $CONTAINERS; do
    echo "Contenedor: $container"
    docker inspect "$container" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "  No tiene etiquetas Traefik"
done

echo ""
echo "3️⃣ Aplicando etiquetas Traefik con método alternativo..."
echo ""

# Método 1: Usar docker service update con todas las etiquetas en un solo comando
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard-checkin24hs.service=dashboard-checkin24hs" \
    --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
    --label-add "traefik.docker.network=easypanel" \
    "$DASHBOARD_SERVICE" 2>&1

echo ""
echo "Esperando 15 segundos para que el servicio se actualice..."
sleep 15

echo ""
echo "4️⃣ Verificando etiquetas después de aplicar..."
echo ""
echo "--- Etiquetas del servicio (método 1) ---"
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "❌ No se encontraron etiquetas Traefik"

echo ""
echo "--- Etiquetas del servicio (método 2 - formato JSON) ---"
docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | grep -i traefik || echo "❌ No se encontraron etiquetas Traefik en JSON"

echo ""
echo "5️⃣ Verificando si EasyPanel está sobrescribiendo las etiquetas..."
echo "   (Si las etiquetas desaparecen, EasyPanel las está sobrescribiendo)"
echo ""

echo "6️⃣ Esperando 30 segundos y verificando de nuevo..."
sleep 30

echo ""
echo "--- Verificación final ---"
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "❌ Las etiquetas desaparecieron (probablemente EasyPanel las sobrescribió)"

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Si las etiquetas NO aparecen, significa que:"
echo "  1. EasyPanel está sobrescribiendo las etiquetas automáticamente"
echo "  2. Necesitas configurar el dominio desde EasyPanel"
echo ""
echo "Solución recomendada:"
echo "  1. Ve a EasyPanel → Servicio dashboard"
echo "  2. Ve a la pestaña 'Dominios' o 'Domains'"
echo "  3. Agrega el dominio: dashboard.checkin24hs.com"
echo "  4. EasyPanel aplicará las etiquetas Traefik automáticamente"
echo ""
