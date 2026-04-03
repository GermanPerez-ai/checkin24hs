#!/bin/bash
cd /root/checkin24hs

echo "=== FORZANDO CORRECCIÓN DE from_me ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontro contenedor de dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Copiar archivo local si existe
if [ -f "deploy/dashboard.html" ]; then
    echo "1. Copiando archivo local al contenedor..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
else
    echo "1. ⚠️ Archivo local no existe, solo corrigiendo en contenedor"
fi

echo ""

# Paso 2: Corregir TODAS las ocurrencias de from_me a is_from_me en el select
echo "2. Corrigiendo 'from_me' a 'is_from_me' en el contenedor..."
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# También corregir cualquier otra variación
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 3: Verificar corrección
echo "3. Verificando corrección..."
HAS_IS_FROM_ME=$(docker exec "$CONTAINER" grep -c "\.select.*is_from_me" /app/dashboard.html 2>/dev/null || echo "0")
HAS_FROM_ME=$(docker exec "$CONTAINER" grep -c "\.select.*from_me" /app/dashboard.html 2>/dev/null || echo "0")

echo "   Ocurrencias de 'is_from_me' en select: $HAS_IS_FROM_ME"
echo "   Ocurrencias de 'from_me' en select: $HAS_FROM_ME"

if [ "$HAS_IS_FROM_ME" -gt 0 ] && [ "$HAS_FROM_ME" -eq 0 ]; then
    echo "   ✅ Corrección verificada correctamente"
else
    echo "   ⚠️ Aún hay problemas, aplicando corrección adicional..."
    # Corrección más agresiva: reemplazar cualquier from_me en contexto de select
    docker exec "$CONTAINER" sed -i 's/from_me/is_from_me/g' /app/dashboard.html
    echo "   ✅ Corrección adicional aplicada"
fi

echo ""

# Paso 4: Mostrar líneas relevantes para verificación
echo "4. Mostrando líneas relevantes para verificación:"
docker exec "$CONTAINER" grep -n "\.select.*from_me\|\.select.*is_from_me" /app/dashboard.html | head -5
echo ""

# Paso 5: Reiniciar Node.js
echo "5. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 5

# Verificar que Node.js está corriendo
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Node.js reiniciado correctamente"
else
    echo "   ⚠️ Esperando más tiempo para Node.js..."
    sleep 5
    if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Node.js está corriendo ahora"
    else
        echo "   ⚠️ Node.js puede necesitar iniciarse manualmente"
    fi
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "⚠️ IMPORTANTE: Para que los cambios surtan efecto:"
echo "1. Abre el dashboard en modo incógnito O"
echo "2. Presiona Ctrl+Shift+R (Cmd+Shift+R en Mac) para forzar recarga O"
echo "3. Limpia completamente el caché del navegador"
echo ""
echo "El error 'column whatsapp_messages.from_me does not exist' debería estar resuelto."


