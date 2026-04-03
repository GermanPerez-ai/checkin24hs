#!/bin/bash
# Script para revertir el servicio y aplicar solución alternativa

echo "=========================================="
echo "🔄 REVIRTIENDO Y SOLUCIONANDO DASHBOARD"
echo "=========================================="
echo ""

SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    exit 1
fi

echo "✅ Servicio: $SERVICE_NAME"
echo ""

# 1. Ver imagen original del servicio
echo "1️⃣ Buscando imagen original del servicio..."
ORIGINAL_IMAGE=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
echo "   Imagen actual: $ORIGINAL_IMAGE"
echo ""

# 2. Ver historial de actualizaciones del servicio
echo "2️⃣ Revisando historial de actualizaciones..."
docker service ps "$SERVICE_NAME" --no-trunc | head -5
echo ""

# 3. Intentar revertir a la versión anterior
echo "3️⃣ Intentando revertir a la versión anterior..."
docker service rollback "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Rollback iniciado"
    echo "   ⏳ Esperando 20 segundos..."
    sleep 20
else
    echo "   ⚠️  No se pudo hacer rollback automático"
    echo "   Intentando restaurar imagen original manualmente..."
    
    # Buscar imagen original en el historial
    PREVIOUS_IMAGE=$(docker service ps "$SERVICE_NAME" --format "{{.Image}}" --no-trunc | head -2 | tail -1)
    if [ ! -z "$PREVIOUS_IMAGE" ] && [ "$PREVIOUS_IMAGE" != "$ORIGINAL_IMAGE" ]; then
        echo "   Restaurando: $PREVIOUS_IMAGE"
        docker service update --image "$PREVIOUS_IMAGE" "$SERVICE_NAME"
        sleep 20
    fi
fi
echo ""

# 4. Verificar estado
echo "4️⃣ Verificando estado del servicio..."
docker service ps "$SERVICE_NAME" --no-trunc | head -3
echo ""

# 5. Si el servicio está funcionando, aplicar solución alternativa
echo "5️⃣ Aplicando solución alternativa (copiar server.js directamente)..."
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor encontrado: $CONTAINER_ID"
    
    # Descargar server.js desde GitHub
    TEMP_DIR="/tmp/dashboard_fix_$(date +%s)"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git
    cd checkin24hs
    
    if [ -f "checkin24hs-admin/server.js" ]; then
        echo "   Copiando server.js al contenedor..."
        docker cp checkin24hs-admin/server.js "$CONTAINER_ID:/app/server.js"
        
        if [ $? -eq 0 ]; then
            echo "   ✅ server.js copiado"
            echo "   ⚠️  Nota: Este cambio se perderá al reiniciar el servicio"
            echo "   Para hacerlo permanente, necesitas actualizar el Dockerfile y hacer rebuild desde EasyPanel"
        else
            echo "   ❌ Error al copiar server.js"
        fi
    else
        echo "   ❌ No se encontró server.js en el repositorio"
    fi
    
    cd /
    rm -rf "$TEMP_DIR"
else
    echo "   ⚠️  No se encontró contenedor en ejecución"
fi
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Próximos pasos recomendados:"
echo "   1. Verificar que el servicio esté funcionando: docker service ps $SERVICE_NAME"
echo "   2. Si server.js se copió, probar: curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "   3. Para hacer el cambio permanente:"
echo "      - Asegúrate de que server.js esté en GitHub"
echo "      - Haz rebuild desde EasyPanel (o espera al próximo deploy automático)"
echo ""
