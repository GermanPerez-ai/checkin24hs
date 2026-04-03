#!/bin/bash
# Script para forzar la reconstrucción de la imagen Docker del dashboard desde GitHub

echo "🔄 FORZANDO RECONSTRUCCIÓN DE LA IMAGEN DOCKER"
echo "=========================================="
echo ""
echo "⚠️ IMPORTANTE: Este script intenta forzar la reconstrucción"
echo "   Si no funciona, necesitas hacerlo manualmente en EasyPanel"
echo ""

# 1. Buscar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)
DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Dashboard encontrado: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Obtener imagen actual
echo "2️⃣ Obteniendo información de la imagen actual..."
CURRENT_IMAGE=$(docker service inspect $DASHBOARD_SERVICE --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)
echo "   Imagen actual: $CURRENT_IMAGE"
echo ""

# 3. Intentar forzar reconstrucción agregando una etiqueta temporal
echo "3️⃣ Intentando forzar reconstrucción..."
echo "   Método 1: Agregar etiqueta temporal para forzar rebuild..."

# Agregar una etiqueta temporal que cambie cada vez
TIMESTAMP=$(date +%s)
docker service update \
    --label-add "force-rebuild=$TIMESTAMP" \
    --label-add "last-update=$(date -Iseconds)" \
    $DASHBOARD_SERVICE

if [ $? -eq 0 ]; then
    echo "   ✅ Etiquetas agregadas"
else
    echo "   ⚠️ No se pudieron agregar etiquetas"
fi
echo ""

# 4. Verificar si EasyPanel tiene API para forzar rebuild
echo "4️⃣ Verificando si hay forma de forzar rebuild desde línea de comandos..."
echo "   ⚠️ EasyPanel normalmente requiere hacer rebuild desde la interfaz web"
echo ""

# 5. Instrucciones para EasyPanel
echo "=========================================="
echo "📋 INSTRUCCIONES PARA RECONSTRUIR EN EASYPANEL"
echo "=========================================="
echo ""
echo "1️⃣ Abre EasyPanel en tu navegador"
echo "2️⃣ Ve al proyecto 'checkin24hs'"
echo "3️⃣ Abre el servicio 'checkin24hs-dashboard' (o 'dashboard')"
echo "4️⃣ Ve a la pestaña 'Deployments' o 'Implementaciones'"
echo "5️⃣ Haz clic en 'Redeploy' o 'Rebuild' o 'Reconstruir'"
echo "6️⃣ Espera 3-5 minutos a que termine la construcción"
echo ""
echo "O alternativamente:"
echo ""
echo "1️⃣ Ve a la pestaña 'Source' o 'Fuente'"
echo "2️⃣ Haz clic en 'Save' o 'Guardar' (aunque no cambies nada)"
echo "3️⃣ Esto debería forzar una nueva construcción"
echo ""
echo "=========================================="
echo ""

# 6. Verificar después de reconstrucción
echo "5️⃣ Después de reconstruir en EasyPanel, ejecuta:"
echo "   ./VERIFICAR_VERSION_CODIGO_SERVIDOR.sh"
echo ""
echo "   Esto verificará si el código nuevo está en el contenedor"
echo ""
