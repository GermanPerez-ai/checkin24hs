#!/bin/bash
# Script para verificar y forzar deploy del dashboard

echo "==========================================="
echo "🔄 Forzar Deploy del Dashboard"
echo "==========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

# 1. Verificar estado actual
echo "1️⃣ Verificando estado actual del servicio..."
SERVICE_STATUS=$(docker service ps "$DASHBOARD_SERVICE" --format "{{.CurrentState}}" | head -1)
SERVICE_IMAGE=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)

echo "   Estado: $SERVICE_STATUS"
echo "   Imagen: $SERVICE_IMAGE"
echo ""

# 2. Verificar versión en el contenedor
echo "2️⃣ Verificando versión en el contenedor..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -n "$CONTAINER_ID" ]; then
    HAS_BUILD_TS=$(docker exec "$CONTAINER_ID" grep -i "BUILD_TIMESTAMP" /app/dashboard.html 2>/dev/null | wc -l)
    HAS_VERSION=$(docker exec "$CONTAINER_ID" grep -i "DASHBOARD_VERSION" /app/dashboard.html 2>/dev/null | wc -l)
    
    if [ "$HAS_BUILD_TS" -eq 0 ] || [ "$HAS_VERSION" -eq 0 ]; then
        echo "   ❌ El contenedor tiene una versión ANTIGUA"
        echo "      BUILD_TIMESTAMP encontrado: $HAS_BUILD_TS"
        echo "      DASHBOARD_VERSION encontrado: $HAS_VERSION"
        echo ""
        echo "   ⚠️  NECESITAS HACER UN DEPLOY EN EASYPANEL"
    else
        echo "   ✅ El contenedor tiene la versión correcta"
    fi
else
    echo "   ❌ No se encontró contenedor"
fi

echo ""

# 3. Verificar última actualización de la imagen
echo "3️⃣ Verificando última actualización de la imagen..."
IMAGE_CREATED=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{.UpdatedAt}}' 2>/dev/null)
echo "   Última actualización: $IMAGE_CREATED"
echo ""

# 4. Instrucciones para hacer deploy
echo "==========================================="
echo "📋 INSTRUCCIONES PARA HACER DEPLOY"
echo "==========================================="
echo ""
echo "El contenedor tiene una versión antigua del dashboard."
echo "Necesitas hacer un nuevo deploy en EasyPanel:"
echo ""
echo "1️⃣ Abre EasyPanel en tu navegador"
echo "   (Normalmente: http://72.61.58.240:3000 o la IP de tu servidor)"
echo ""
echo "2️⃣ Ve al proyecto 'checkin24hs'"
echo ""
echo "3️⃣ Haz clic en el servicio 'dashboard'"
echo ""
echo "4️⃣ Busca el botón 'Deploy' o 'Redeploy' (botón verde grande)"
echo ""
echo "5️⃣ Haz clic en 'Deploy' y espera 3-5 minutos"
echo ""
echo "6️⃣ Verifica que el servicio esté en estado 'Running' (verde)"
echo ""
echo "7️⃣ Después del deploy, ejecuta este script de nuevo:"
echo "   ./VERIFICAR_VERSION_CONTENEDOR.sh"
echo ""
echo "==========================================="
echo "🔍 Verificación Rápida"
echo "==========================================="
echo ""
echo "Para verificar si el deploy se completó, ejecuta:"
echo "  docker service ps $DASHBOARD_SERVICE"
echo ""
echo "Para verificar la versión después del deploy:"
echo "  CONTAINER=\$(docker ps --filter \"name=dashboard\" --format \"{{.ID}}\" | head -1)"
echo "  docker exec \$CONTAINER grep -i 'BUILD_TIMESTAMP' /app/dashboard.html | head -1"
echo ""
