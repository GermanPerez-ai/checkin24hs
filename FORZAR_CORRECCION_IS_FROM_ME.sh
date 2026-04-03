#!/bin/bash
cd /root/checkin24hs

echo "=== FORZANDO CORRECCIÓN IS_FROM_ME ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Copiar archivo completo si existe
if [ -f "deploy/dashboard.html" ]; then
    echo "1. Copiando archivo completo desde deploy/dashboard.html..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "1. ⚠️ Archivo deploy/dashboard.html no existe, corrigiendo directamente..."
fi

# Paso 2: Buscar TODAS las instancias de from_me en el contexto de select
echo ""
echo "2. Buscando TODAS las instancias de 'from_me' (incorrecto)..."
docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -10
echo ""

# Paso 3: Corregir TODAS las variaciones posibles de forma más agresiva
echo "3. Corrigiendo TODAS las variaciones..."

# Primero, corregir cualquier patrón que tenga 'from_me' sin 'is_' antes en el contexto de select
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corregir con espacios variables
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at,from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at,from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corregir variaciones múltiples de is_is_is...
docker exec "$CONTAINER" sed -i 's/is_is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html

# Corregir cualquier .select que tenga from_me
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Buscar y reemplazar cualquier patrón más genérico
docker exec "$CONTAINER" sed -i "s/, from_me'/, is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/, from_me"/, is_from_me"/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/,from_me'/, is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/,from_me"/, is_from_me"/g' /app/dashboard.html

# Pero solo en el contexto de select, no queremos cambiar otras cosas
# Así que revertimos si cambiamos algo que no deberíamos
docker exec "$CONTAINER" sed -i 's/is_from_me_from_me/is_from_me/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 4: Verificar que quedó correcto
echo "4. Verificando corrección..."
echo "   Buscando 'from_me' sin 'is_' (NO debería aparecer):"
if docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -5; then
    echo "   ⚠️ AÚN HAY 'from_me' INCORRECTO"
    echo "   Intentando corrección adicional..."
    # Corrección adicional más agresiva
    docker exec "$CONTAINER" sed -i 's/\bfrom_me\b/is_from_me/g' /app/dashboard.html
else
    echo "   ✅ No hay 'from_me' incorrecto"
fi

echo ""
echo "   Buscando 'is_from_me' (debería aparecer):"
docker exec "$CONTAINER" grep -n "is_from_me" /app/dashboard.html | head -5
echo ""

# Paso 5: Mostrar la línea específica (24521)
echo "5. Mostrando líneas alrededor de 24521:"
docker exec "$CONTAINER" sed -n '24519,24523p' /app/dashboard.html
echo ""

# Paso 6: Verificar que el archivo tiene el código correcto
echo "6. Verificando contenido del select:"
if docker exec "$CONTAINER" grep -q "select('id, chat_id, body, created_at, is_from_me')" /app/dashboard.html; then
    echo "   ✅ Select correcto encontrado"
else
    echo "   ⚠️ Select correcto NO encontrado, buscando variaciones..."
    docker exec "$CONTAINER" grep -n "select.*is_from_me" /app/dashboard.html | head -3
fi

echo ""

# Paso 7: Reiniciar Node.js
echo "7. Reiniciando Node.js..."
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
echo "3. Abre la consola del navegador (F12) y verifica que la URL tenga 'is_from_me'"
echo ""
echo "La URL debería ser:"
echo "  whatsapp_messages?select=id%2Cchat_id%2Cbody%2Ccreated_at%2Cis_from_me"
echo "Y NO:"
echo "  whatsapp_messages?select=id%2Cchat_id%2Cbody%2Ccreated_at%2Cfrom_me"


