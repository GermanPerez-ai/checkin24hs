#!/bin/bash
cd /root/checkin24hs

echo "=== CORRIGIENDO FROM_ME DEFINITIVAMENTE ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Verificar qué tiene actualmente
echo "1. Verificando estado actual del archivo..."
echo "   Buscando 'from_me' (incorrecto):"
docker exec "$CONTAINER" grep -n "\.select.*from_me" /app/dashboard.html | head -5
echo ""
echo "   Buscando 'is_from_me' (correcto):"
docker exec "$CONTAINER" grep -n "\.select.*is_from_me" /app/dashboard.html | head -5
echo ""

# Paso 2: Copiar archivo completo si existe
if [ -f "deploy/dashboard.html" ]; then
    echo "2. Copiando archivo completo desde deploy/dashboard.html..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "2. ⚠️ Archivo deploy/dashboard.html no existe, corrigiendo directamente..."
fi

# Paso 3: Corregir TODAS las variaciones posibles
echo ""
echo "3. Corrigiendo todas las variaciones incorrectas..."

# Reemplazar from_me por is_from_me en el select
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corregir variaciones múltiples
docker exec "$CONTAINER" sed -i 's/is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_is_is_from_me/is_from_me/g' /app/dashboard.html

# Corregir cualquier patrón con from_me en el select
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 4: Verificar que quedó correcto
echo "4. Verificando corrección..."
echo "   Buscando 'from_me' (NO debería aparecer):"
if docker exec "$CONTAINER" grep -n "\.select.*from_me" /app/dashboard.html | grep -v "is_from_me" | head -3; then
    echo "   ⚠️ AÚN HAY 'from_me' INCORRECTO"
else
    echo "   ✅ No hay 'from_me' incorrecto"
fi

echo ""
echo "   Buscando 'is_from_me' (debería aparecer):"
docker exec "$CONTAINER" grep -n "\.select.*is_from_me" /app/dashboard.html | head -3
echo ""

# Paso 5: Mostrar la línea específica (24521)
echo "5. Mostrando línea 24521 (donde debería estar el select):"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""

# Paso 6: Reiniciar Node.js
echo "6. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 5

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
echo "2. Presiona Ctrl+Shift+R (Cmd+Shift+R en Mac) para forzar recarga"
echo "3. Verifica en la consola del navegador que la URL tenga 'is_from_me' y NO 'from_me'"
echo ""
echo "La URL debería ser:"
echo "  whatsapp_messages?select=id%2Cchat_id%2Cbody%2Ccreated_at%2Cis_from_me"
echo "Y NO:"
echo "  whatsapp_messages?select=id%2Cchat_id%2Cbody%2Ccreated_at%2Cfrom_me"
