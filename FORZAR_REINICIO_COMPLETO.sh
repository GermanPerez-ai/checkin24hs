#!/bin/bash
# Forzar reinicio completo del contenedor después de copiar el archivo

echo "=== FORZAR REINICIO COMPLETO ==="
echo ""

# 1. Verificar archivo local
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra deploy/dashboard.html"
    exit 1
fi

LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "📄 Archivo local: $LOCAL_SIZE bytes"
grep -q "whatsapp-config-button-main" deploy/dashboard.html && \
    echo "✅ Contiene botones" || \
    echo "❌ NO contiene botones"
echo ""

# 2. Obtener contenedor actual
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor actual: $CONTAINER"
echo ""

# 3. Copiar archivo ANTES de reiniciar
echo "📤 Copiando archivo al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
echo "✅ Copiado"
echo ""

# 4. Verificar que se copió correctamente
FILE_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
echo "Tamaño en contenedor: $FILE_SIZE bytes"

if [ "$FILE_SIZE" = "$LOCAL_SIZE" ]; then
    echo "✅ Tamaño coincide"
else
    echo "⚠️  Tamaño NO coincide"
fi

docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
    echo "✅ Contiene botones" || \
    echo "❌ NO contiene botones"
echo ""

# 5. Reiniciar el CONTENEDOR completo (no solo el proceso)
echo "🔄 Reiniciando contenedor completo..."
docker restart "$CONTAINER"
echo "✅ Contenedor reiniciado"
echo ""

# 6. Esperar a que el contenedor se inicie completamente
echo "⏳ Esperando 30 segundos para que el contenedor se inicie..."
sleep 30

# 7. Verificar nuevo contenedor (puede tener un nombre diferente después del reinicio)
NEW_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "📦 Nuevo contenedor: $NEW_CONTAINER"
echo ""

# 8. Verificar archivo en nuevo contenedor
if [ -n "$NEW_CONTAINER" ]; then
    echo "🔍 Verificando archivo en nuevo contenedor:"
    NEW_FILE_SIZE=$(docker exec "$NEW_CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$NEW_CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null)
    echo "   Tamaño: $NEW_FILE_SIZE bytes"
    
    if [ "$NEW_FILE_SIZE" != "$LOCAL_SIZE" ]; then
        echo "   ⚠️  Archivo se sobrescribió, copiando nuevamente..."
        docker cp deploy/dashboard.html "${NEW_CONTAINER}:/app/dashboard.html"
        sleep 5
    fi
    
    docker exec "$NEW_CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
    
    echo ""
    echo "🔍 Verificando logs del servidor:"
    docker logs "$NEW_CONTAINER" --tail 10 2>&1 | grep -iE "servidor|iniciado|error" | tail -5
    echo ""
    
    # 9. Esperar un poco más y verificar acceso
    echo "⏳ Esperando 10 segundos adicionales..."
    sleep 10
    
    echo ""
    echo "🌍 Verificando contenido servido por HTTPS:"
    HTTPS_RESPONSE=$(curl -s https://dashboard.checkin24hs.com 2>&1)
    HTTPS_SIZE=$(echo "$HTTPS_RESPONSE" | wc -c)
    echo "   Tamaño servido: $HTTPS_SIZE bytes"
    
    echo "$HTTPS_RESPONSE" | grep -q "whatsapp-config-button-main" && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
else
    echo "❌ No se encontró contenedor después del reinicio"
fi

echo ""
echo "=== COMPLETADO ==="





