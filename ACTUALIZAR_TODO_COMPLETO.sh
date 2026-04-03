#!/bin/bash

cd /root/checkin24hs

echo "=== Actualización completa del dashboard ==="
echo ""

# 1. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 2. Copiar archivos actualizados
echo "=== 1. Copiando archivos actualizados ==="
if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "✅ dashboard.html copiado"
else
    echo "⚠️ No se encontró deploy/dashboard.html"
fi

if [ -f "deploy/supabase-client.js" ]; then
    docker cp deploy/supabase-client.js "${CONTAINER}:/app/supabase-client.js"
    echo "✅ supabase-client.js copiado"
else
    echo "⚠️ No se encontró deploy/supabase-client.js"
fi

# 3. Corregir from_me en dashboard.html
echo ""
echo "=== 2. Corrigiendo from_me en dashboard.html ==="
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# 4. Verificar corrección
echo ""
echo "=== 3. Verificación ==="
echo "Línea 24521:"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""
echo "Buscando instancias incorrectas (NO debería aparecer nada):"
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -3

# 5. Verificar filtro de spam
echo ""
echo "=== 4. Verificando filtro de spam ==="
docker exec "$CONTAINER" grep -n "spamPatterns" /app/dashboard.html | head -2

# 6. Reiniciar contenedor
echo ""
echo "=== 5. Reiniciando contenedor ==="
docker restart "$CONTAINER"

echo "Esperando 25 segundos..."
sleep 25

echo ""
echo "✅ COMPLETADO"
echo ""
echo "📋 Cambios aplicados:"
echo "  1. ✅ dashboard.html actualizado (filtro de spam mejorado con @lid, @newsletter, @g.us)"
echo "  2. ✅ supabase-client.js actualizado (filtro de spam desde Supabase)"
echo "  3. ✅ dashboard.html corregido (is_from_me)"
echo "  4. ✅ Contenedor reiniciado"
echo ""
echo "⚠️ IMPORTANTE - En TODAS las computadoras:"
echo "  1. Cierra TODAS las pestañas del dashboard"
echo "  2. Presiona Ctrl+Shift+Delete"
echo "  3. Selecciona 'Cached images and files' y 'Cookies'"
echo "  4. Selecciona 'All time'"
echo "  5. Haz clic en 'Clear data'"
echo "  6. Cierra completamente el navegador"
echo "  7. Abre el navegador de nuevo"
echo "  8. Abre el dashboard en modo incógnito (Ctrl+Shift+N)"
echo "  9. Con DevTools abierto (F12), ve a Network"
echo "  10. Marca 'Disable cache'"
echo "  11. Recarga la página (F5)"


