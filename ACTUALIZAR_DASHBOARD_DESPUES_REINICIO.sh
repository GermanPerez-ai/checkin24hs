#!/bin/bash
# Actualizar dashboard después de reiniciar el servicio

echo "=== ACTUALIZAR DASHBOARD DESPUÉS DE REINICIO ==="
echo ""

# 1. Verificar archivo local
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra deploy/dashboard.html"
    exit 1
fi

echo "✅ Archivo local verificado"
LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "   Tamaño: $LOCAL_SIZE bytes"
echo ""

# 2. Esperar a que el servicio esté corriendo
echo "⏳ Esperando a que el servicio esté corriendo..."
for i in {1..30}; do
    CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
    if [ -n "$CONTAINER" ]; then
        echo "   ✅ Contenedor encontrado: $CONTAINER"
        break
    fi
    sleep 1
done

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor después de 30 segundos"
    exit 1
fi

echo ""

# 3. Esperar a que el contenedor esté completamente iniciado
echo "⏳ Esperando a que el contenedor esté completamente iniciado..."
sleep 10

# 4. Copiar archivo
echo "📤 Copiando dashboard.html al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi

echo ""

# 5. Verificar que se copió correctamente
echo "🔍 Verificando archivo copiado:"
FILE_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
echo "   Tamaño: $FILE_SIZE bytes"

if [ "$FILE_SIZE" = "$LOCAL_SIZE" ]; then
    echo "   ✅ Tamaño coincide"
else
    echo "   ⚠️  Tamaño NO coincide (esperado: $LOCAL_SIZE, actual: $FILE_SIZE)"
fi

docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"

echo ""

# 6. Reiniciar solo el proceso Node.js dentro del contenedor (no el contenedor completo)
echo "🔄 Reiniciando proceso Node.js..."
docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || true
sleep 5

# Verificar que el proceso se reinició
echo "   Verificando proceso..."
docker exec "$CONTAINER" ps aux | grep node | head -3
echo ""

# 7. Esperar y verificar
echo "⏳ Esperando 15 segundos..."
sleep 15

# 8. Verificar contenido servido (usando wget si curl no está disponible)
echo ""
echo "🌍 Verificando contenido servido:"
# Intentar con wget primero
RESPONSE=$(docker exec "$CONTAINER" wget -qO- http://localhost:3000/ 2>/dev/null || echo "")

if [ -n "$RESPONSE" ]; then
    echo "$RESPONSE" | grep -q "whatsapp-config-button-main" && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
    
    RESPONSE_SIZE=$(echo "$RESPONSE" | wc -c)
    echo "   Tamaño de respuesta: $RESPONSE_SIZE bytes"
else
    echo "   ⚠️  No se pudo verificar (wget no disponible o servidor no responde)"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📋 Para aplicar cambios después de cada reinicio del servicio, ejecuta:"
echo "   bash ACTUALIZAR_DASHBOARD_DESPUES_REINICIO.sh"
echo ""





