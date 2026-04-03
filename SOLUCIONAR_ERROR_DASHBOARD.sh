#!/bin/bash
# Script para solucionar el error del dashboard

echo "=========================================="
echo "🔧 SOLUCIONANDO ERROR DEL DASHBOARD"
echo "=========================================="
echo ""

SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    exit 1
fi

echo "✅ Servicio: $SERVICE_NAME"
echo ""

# 1. Ver logs para entender el error
echo "1️⃣ Revisando logs del servicio..."
docker service logs "$SERVICE_NAME" --tail 30 --no-trunc 2>&1 | tail -20
echo ""

# 2. Verificar imagen actual
echo "2️⃣ Imagen actual del servicio:"
CURRENT_IMAGE=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
echo "   $CURRENT_IMAGE"
echo ""

# 3. Verificar si la imagen nueva existe
echo "3️⃣ Verificando imágenes disponibles:"
NEW_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "checkin24hs/dashboard:latest-" | head -1)
if [ ! -z "$NEW_IMAGE" ]; then
    echo "   ✅ Nueva imagen encontrada: $NEW_IMAGE"
    
    # Probar ejecutar la imagen manualmente
    echo ""
    echo "4️⃣ Probando ejecutar la imagen manualmente..."
    TEST_CONTAINER=$(docker run -d --rm -p 3001:3000 "$NEW_IMAGE" 2>&1)
    
    if echo "$TEST_CONTAINER" | grep -q "Error\|error\|failed"; then
        echo "   ❌ Error al ejecutar la imagen:"
        echo "$TEST_CONTAINER"
        echo ""
        echo "   Revisando logs del contenedor de prueba..."
        sleep 2
        if [ ! -z "$TEST_CONTAINER" ] && [ ${#TEST_CONTAINER} -eq 64 ]; then
            docker logs "$TEST_CONTAINER" 2>&1 | tail -20
            docker stop "$TEST_CONTAINER" 2>/dev/null
        fi
    else
        echo "   ✅ Imagen se ejecutó correctamente"
        CONTAINER_ID=$(echo "$TEST_CONTAINER" | head -1)
        sleep 2
        echo "   Logs del contenedor de prueba:"
        docker logs "$CONTAINER_ID" 2>&1 | tail -10
        docker stop "$CONTAINER_ID" 2>/dev/null
    fi
else
    echo "   ⚠️  No se encontró imagen nueva"
fi
echo ""

# 5. Verificar si el problema es el registry
echo "5️⃣ Verificando si necesitamos usar el registry de EasyPanel..."
EASYPANEL_IMAGE=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' | grep -o "easypanel/[^:]*" || echo "")
if [ ! -z "$EASYPANEL_IMAGE" ]; then
    echo "   El servicio usa imágenes de EasyPanel: $EASYPANEL_IMAGE"
    echo "   ⚠️  Puede que necesitemos hacer push a EasyPanel o usar otra estrategia"
fi
echo ""

echo "=========================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Próximos pasos sugeridos:"
echo "   1. Si la imagen falla, revisa los logs arriba"
echo "   2. Si el problema es el registry, necesitamos hacer push a EasyPanel"
echo "   3. O podemos actualizar el archivo directamente en el contenedor"
echo ""
