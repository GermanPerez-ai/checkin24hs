#!/bin/bash
cd /root/checkin24hs

echo "=== CORRECCIÓN FINAL DE from_me ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Copiar archivo local
if [ -f "deploy/dashboard.html" ]; then
    echo "1. Copiando archivo local al contenedor..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "1. ⚠️ Archivo local no existe, solo corrigiendo en contenedor"
fi

echo ""

# Paso 2: Corrección agresiva - múltiples patrones
echo "2. Aplicando corrección agresiva..."

# Mostrar qué hay antes
echo "   ANTES de la corrección:"
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | head -3 || echo "   (no encontrado)"

# Aplicar correcciones múltiples
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corrección más específica: reemplazar from_me en contexto de whatsapp_messages
docker exec "$CONTAINER" sed -i '/whatsapp_messages/,/limit/s/from_me/is_from_me/g' /app/dashboard.html

# Corrección final: cualquier from_me que esté en un select
docker exec "$CONTAINER" sed -i 's/select([^)]*from_me[^)]*)/select(\1)/g' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i "s/select('[^']*from_me[^']*')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 3: Verificar corrección
echo "3. Verificando corrección..."
echo "   DESPUÉS de la corrección:"
docker exec "$CONTAINER" grep -n "select.*from_me\|select.*is_from_me" /app/dashboard.html | head -5

FROM_ME_COUNT=$(docker exec "$CONTAINER" grep -c "select.*from_me" /app/dashboard.html 2>/dev/null || echo "0")
IS_FROM_ME_COUNT=$(docker exec "$CONTAINER" grep -c "select.*is_from_me" /app/dashboard.html 2>/dev/null || echo "0")

echo ""
echo "   Ocurrencias de 'from_me' en select: $FROM_ME_COUNT"
echo "   Ocurrencias de 'is_from_me' en select: $IS_FROM_ME_COUNT"

if [ "$FROM_ME_COUNT" -gt 0 ]; then
    echo "   ⚠️ Aún hay 'from_me', aplicando corrección final..."
    # Última corrección: reemplazar cualquier from_me que esté en un select
    docker exec "$CONTAINER" sed -i 's/from_me/is_from_me/g' /app/dashboard.html
    echo "   ✅ Corrección final aplicada"
    
    # Verificar nuevamente
    FROM_ME_COUNT=$(docker exec "$CONTAINER" grep -c "select.*from_me" /app/dashboard.html 2>/dev/null || echo "0")
    IS_FROM_ME_COUNT=$(docker exec "$CONTAINER" grep -c "select.*is_from_me" /app/dashboard.html 2>/dev/null || echo "0")
    echo "   Después de corrección final - from_me: $FROM_ME_COUNT, is_from_me: $IS_FROM_ME_COUNT"
fi

echo ""

# Paso 4: Mostrar líneas específicas para confirmación
echo "4. Mostrando líneas específicas alrededor de la corrección:"
docker exec "$CONTAINER" sed -n '24518,24525p' /app/dashboard.html
echo ""

# Paso 5: Reiniciar Node.js
echo "5. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 5

# Verificar que Node.js está corriendo
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Node.js reiniciado correctamente"
else
    echo "   ⚠️ Esperando más tiempo..."
    sleep 5
    if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Node.js está corriendo ahora"
    else
        echo "   ❌ Node.js no está corriendo"
    fi
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "⚠️ IMPORTANTE:"
echo "1. Abre el dashboard en modo incógnito O"
echo "2. Presiona Ctrl+Shift+R (Cmd+Shift+R en Mac) para forzar recarga O"
echo "3. Limpia completamente el caché del navegador"
echo ""
echo "El error 'column whatsapp_messages.from_me does not exist' debería estar resuelto."


