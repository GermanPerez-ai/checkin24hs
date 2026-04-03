#!/bin/bash

cd /root/checkin24hs

echo "=== Actualizando código en el servidor ==="
echo ""

# 1. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 2. Copiar supabase-client.js actualizado
echo "=== 1. Copiando supabase-client.js actualizado ==="
if [ -f "deploy/supabase-client.js" ]; then
    docker cp deploy/supabase-client.js "${CONTAINER}:/app/supabase-client.js"
    echo "✅ supabase-client.js copiado"
else
    echo "⚠️ No se encontró deploy/supabase-client.js"
fi

# 3. Verificar y corregir dashboard.html (asegurar is_from_me)
echo ""
echo "=== 2. Verificando dashboard.html ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html

# Corregir from_me si es necesario
echo ""
echo "=== 3. Corrigiendo from_me en dashboard.html ==="
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Verificar corrección
echo ""
echo "=== 4. Verificación final ==="
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""
echo "Buscando instancias incorrectas (NO debería aparecer nada):"
docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -3

# 5. Reiniciar contenedor
echo ""
echo "=== 5. Reiniciando contenedor ==="
docker restart "$CONTAINER"

echo "Esperando 25 segundos..."
sleep 25

echo ""
echo "✅ COMPLETADO"
echo ""
echo "📋 Cambios aplicados:"
echo "  1. ✅ supabase-client.js actualizado (filtro de spam mejorado)"
echo "  2. ✅ dashboard.html corregido (is_from_me)"
echo "  3. ✅ Contenedor reiniciado"
echo ""
echo "⚠️ IMPORTANTE:"
echo "  - Asegúrate de haber ejecutado FILTRAR_SPAM_SUPABASE.sql en Supabase"
echo "  - Limpia el caché del navegador en todas las computadoras"
echo "  - El filtro de spam ahora funciona desde Supabase (más eficiente)"


