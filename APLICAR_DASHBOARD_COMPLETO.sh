#!/bin/bash
cd /root/checkin24hs

echo "=== APLICANDO DASHBOARD COMPLETO ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Copiar archivo local completo
if [ -f "deploy/dashboard.html" ]; then
    echo "1. Copiando archivo completo al contenedor..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "1. ❌ Archivo deploy/dashboard.html no existe"
    exit 1
fi

echo ""

# Paso 2: Corregir problema de is_is_is_from_me (si existe)
echo "2. Corrigiendo variaciones incorrectas de is_from_me..."
docker exec "$CONTAINER" sed -i 's/is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_is_is_from_me/is_from_me/g' /app/dashboard.html

# Asegurar que el select tenga exactamente is_from_me
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, is_is.*from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, is_is.*from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 3: Verificar que tiene el código de filtrado de spam
echo "3. Verificando código de filtrado de spam..."
if docker exec "$CONTAINER" grep -q "spamPatterns" /app/dashboard.html; then
    echo "   ✅ Código de filtrado de spam presente"
else
    echo "   ❌ Código de filtrado de spam NO encontrado"
    echo "   El archivo puede estar corrupto o incompleto"
fi

# Verificar que tiene is_from_me correcto
if docker exec "$CONTAINER" grep -q "select.*is_from_me" /app/dashboard.html; then
    echo "   ✅ Código tiene is_from_me correcto"
else
    echo "   ❌ Código NO tiene is_from_me"
fi

# Verificar que NO tiene variaciones incorrectas
if docker exec "$CONTAINER" grep -q "select.*is_is.*from_me" /app/dashboard.html; then
    echo "   ⚠️ Aún hay variaciones incorrectas"
    docker exec "$CONTAINER" grep -n "select.*is_is.*from_me" /app/dashboard.html | head -3
else
    echo "   ✅ No hay variaciones incorrectas"
fi

echo ""

# Paso 4: Mostrar líneas específicas para confirmación
echo "4. Mostrando líneas específicas:"
echo "   Línea 24521 (select):"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo "   Línea 24317 (spamPatterns):"
docker exec "$CONTAINER" sed -n '24317p' /app/dashboard.html
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
echo "Ahora deberías ver:"
echo "- ✅ Los mensajes se cargan correctamente (sin error de from_me)"
echo "- ✅ Los chats spam están filtrados (no aparecen)"
