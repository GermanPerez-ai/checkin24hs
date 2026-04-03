#!/bin/bash
# Solución definitiva: usar un script de inicialización

echo "=== SOLUCIÓN DEFINITIVA PARA DASHBOARD ==="
echo ""

# 1. Crear script de inicialización que copie el archivo al iniciar
echo "📝 1. Creando script de inicialización..."
cat > /tmp/dashboard-init.sh << 'INITEOF'
#!/bin/sh
# Script que se ejecuta al iniciar el contenedor
# Copiar dashboard.html actualizado si existe en /host-dashboard/

if [ -f "/host-dashboard/dashboard.html" ]; then
    echo "📦 Copiando dashboard.html actualizado..."
    cp /host-dashboard/dashboard.html /app/dashboard.html
    echo "✅ Dashboard actualizado"
else
    echo "⚠️  No se encontró /host-dashboard/dashboard.html"
fi

# Ejecutar el comando original
exec "$@"
INITEOF

chmod +x /tmp/dashboard-init.sh
echo "✅ Script creado"
echo ""

# 2. Verificar archivo local
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra deploy/dashboard.html"
    exit 1
fi

echo "📄 2. Archivo local verificado:"
LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "   Tamaño: $LOCAL_SIZE bytes"
grep -q "whatsapp-config-button-main" deploy/dashboard.html && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"
echo ""

# 3. Actualizar el servicio para usar un volumen y script de inicialización
echo "🔧 3. Actualizando servicio con volumen..."

# Primero, obtener la configuración actual del servicio
echo "   Configuración actual del servicio:"
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null
echo ""

# Crear directorio en el host para el dashboard
mkdir -p /root/checkin24hs/host-dashboard
cp deploy/dashboard.html /root/checkin24hs/host-dashboard/dashboard.html
echo "✅ Archivo copiado a /root/checkin24hs/host-dashboard/"
echo ""

# Actualizar el servicio para montar el volumen
echo "🔧 4. Actualizando servicio con volumen montado..."
docker service update \
  --mount-add type=bind,source=/root/checkin24hs/host-dashboard,destination=/host-dashboard,readonly=true \
  --mount-add type=bind,source=/tmp/dashboard-init.sh,destination=/docker-entrypoint-init.sh \
  checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo ""
echo "⏳ Esperando 30 segundos..."
sleep 30

# 5. Verificar nuevo contenedor
NEW_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo ""
echo "📦 5. Nuevo contenedor: $NEW_CONTAINER"

if [ -n "$NEW_CONTAINER" ]; then
    echo ""
    echo "🔍 Verificando archivo en nuevo contenedor:"
    FILE_SIZE=$(docker exec "$NEW_CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$NEW_CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   Tamaño: $FILE_SIZE bytes"
    
    if [ "$FILE_SIZE" = "$LOCAL_SIZE" ]; then
        echo "   ✅ Tamaño coincide"
    else
        echo "   ⚠️  Tamaño NO coincide (esperado: $LOCAL_SIZE, actual: $FILE_SIZE)"
    fi
    
    docker exec "$NEW_CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
    
    echo ""
    echo "🔍 Verificando logs del contenedor:"
    docker logs "$NEW_CONTAINER" --tail 10 2>&1 | grep -iE "dashboard|init|copy" | tail -5
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📋 Si el volumen no funciona, alternativa:"
echo "   Cada vez que actualices dashboard.html, ejecuta:"
echo "   docker cp deploy/dashboard.html \$(docker ps --filter 'name=checkin24hs_dashboard' --format '{{.Names}}' | head -1):/app/dashboard.html"
echo "   docker service update --force checkin24hs_dashboard"
echo ""





