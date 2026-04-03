#!/bin/bash
cd /root/checkin24hs

echo "=== CORRIGIENDO is_is_is_from_me ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Copiar archivo local (que tiene la versión correcta)
if [ -f "deploy/dashboard.html" ]; then
    echo "1. Copiando archivo local correcto al contenedor..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "1. ⚠️ Archivo local no existe, corrigiendo directamente"
fi

echo ""

# Paso 2: Corregir cualquier variación incorrecta
echo "2. Corrigiendo variaciones incorrectas..."

# Reemplazar cualquier variación incorrecta por la correcta
docker exec "$CONTAINER" sed -i 's/is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_is_is_from_me/is_from_me/g' /app/dashboard.html

# Asegurarse de que el select tenga exactamente is_from_me
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, is_is.*from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, is_is.*from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 3: Verificar corrección
echo "3. Verificando corrección..."
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | head -5

# Contar ocurrencias
CORRECT_COUNT=$(docker exec "$CONTAINER" grep -c "select.*is_from_me" /app/dashboard.html 2>/dev/null || echo "0")
INCORRECT_COUNT=$(docker exec "$CONTAINER" grep -c "select.*is_is.*from_me\|select.*from_me" /app/dashboard.html 2>/dev/null || echo "0")

echo ""
echo "   Ocurrencias correctas (is_from_me): $CORRECT_COUNT"
echo "   Ocurrencias incorrectas: $INCORRECT_COUNT"

if [ "$INCORRECT_COUNT" -eq 0 ] && [ "$CORRECT_COUNT" -gt 0 ]; then
    echo "   ✅ Corrección verificada correctamente"
else
    echo "   ⚠️ Aún hay problemas"
    # Mostrar líneas problemáticas
    docker exec "$CONTAINER" grep -n "select.*is_is\|select.*from_me" /app/dashboard.html | head -5
fi

echo ""

# Paso 4: Mostrar la línea específica que debe estar correcta
echo "4. Mostrando línea específica (24521):"
docker exec "$CONTAINER" sed -n '24519,24523p' /app/dashboard.html
echo ""

# Paso 5: Reiniciar Node.js
echo "5. Reiniciando Node.js..."
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
echo "2. Presiona Ctrl+Shift+R (Cmd+Shift+R en Mac) para forzar recarga O"
echo "3. Limpia completamente el caché del navegador"
echo ""
echo "El error debería estar resuelto ahora."


