#!/bin/bash
# Script para diagnosticar el error del dashboard

echo "=========================================="
echo "🔍 DIAGNOSTICANDO ERROR DEL DASHBOARD"
echo "=========================================="
echo ""

# 1. Ver estado del servicio
echo "1️⃣ Estado del servicio:"
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)
docker service ps "$SERVICE_NAME" --no-trunc
echo ""

# 2. Ver logs recientes
echo "2️⃣ Logs recientes del servicio:"
docker service logs "$SERVICE_NAME" --tail 50 --no-trunc
echo ""

# 3. Verificar si hay contenedores corriendo
echo "3️⃣ Contenedores del servicio:"
docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME"
echo ""

# 4. Verificar imagen actual del servicio
echo "4️⃣ Imagen configurada en el servicio:"
docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'
echo ""

# 5. Verificar si la nueva imagen existe localmente
echo "5️⃣ Imágenes locales del dashboard:"
docker images | grep -i dashboard | head -5
echo ""

# 6. Intentar ejecutar la imagen manualmente para ver el error
echo "6️⃣ Intentando ejecutar la imagen manualmente..."
NEW_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "checkin24hs/dashboard:latest-" | head -1)
if [ ! -z "$NEW_IMAGE" ]; then
    echo "   Imagen: $NEW_IMAGE"
    echo "   Ejecutando contenedor de prueba (se detendrá en 5 segundos)..."
    timeout 5 docker run --rm "$NEW_IMAGE" 2>&1 || echo "   Contenedor se detuvo o falló"
else
    echo "   ⚠️  No se encontró imagen nueva"
fi
echo ""

echo "=========================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=========================================="
