#!/bin/bash

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

echo "=========================================="
echo "🔍 VERIFICACIÓN Y CORRECCIÓN DE MENSAJES"
echo "=========================================="
echo ""

# 1. Verificar si hay mensajes en Supabase (necesitamos las credenciales)
echo "=== 1. Verificando mensajes en Supabase ==="
echo "⚠️ Para verificar mensajes en Supabase, necesitas:"
echo "   - Ir a tu panel de Supabase"
echo "   - Tabla: whatsapp_messages"
echo "   - Verificar si hay registros con chat_id que coincidan con los chats"
echo ""

# 2. Buscar TODAS las consultas problemáticas en el archivo
echo "=== 2. Buscando TODAS las consultas problemáticas ==="
echo "Buscando 'from_me' (sin 'is_'):"
docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10

echo ""
echo "Buscando consultas con 'select' y 'from_me':"
docker exec "$CONTAINER" grep -n "select.*from_me\|from_me.*select" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10

echo ""
echo "Buscando 'verificación directa' o 'Error en verificación':"
docker exec "$CONTAINER" grep -n "verificación\|Error en verificación" /app/dashboard.html | head -10
echo ""

# 3. Buscar el bloque de código problemático alrededor de la línea 24526
echo "=== 3. Revisando código alrededor de línea 24526 ==="
docker exec "$CONTAINER" sed -n '24510,24540p' /app/dashboard.html
echo ""

# 4. Buscar cualquier bloque try-catch que haga consultas directas
echo "=== 4. Buscando bloques try-catch problemáticos ==="
docker exec "$CONTAINER" grep -n "try {" /app/dashboard.html | grep -A 5 -B 5 "select.*from_me" | head -20 || echo "No se encontraron bloques obvios"
echo ""

# 5. Buscar si hay código que haga consultas ANTES de getWhatsAppMessages
echo "=== 5. Buscando consultas antes de getWhatsAppMessages ==="
# Buscar líneas que contengan tanto "getWhatsAppMessages" como consultas directas cerca
docker exec "$CONTAINER" awk '/getWhatsAppMessages/{found=1; line=NR} found && NR<=line+20 && /select.*from_me/ && !/is_from_me/ {print NR": "$0}' /app/dashboard.html | head -10 || echo "No se encontraron consultas problemáticas cerca de getWhatsAppMessages"
echo ""

# 6. Buscar cualquier referencia a whatsapp_messages con select
echo "=== 6. Buscando consultas directas a whatsapp_messages ==="
docker exec "$CONTAINER" grep -n "whatsapp_messages.*select\|select.*whatsapp_messages" /app/dashboard.html | head -10
echo ""

# 7. Mostrar el código completo de la función selectChat
echo "=== 7. Buscando función selectChat completa ==="
docker exec "$CONTAINER" awk '/window\.selectChat|function selectChat|const selectChat|selectChat\s*=\s*async/,/^[[:space:]]*}/' /app/dashboard.html | head -50
echo ""

# 8. Crear un script de corrección más agresivo
echo "=== 8. Aplicando corrección agresiva ==="

# Eliminar cualquier línea que contenga consultas con from_me (excepto comentarios)
docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/select.*from_me[^_].*)/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante con is_from_me
docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html

echo "✅ Corrección agresiva aplicada"
echo ""

# 9. Verificar nuevamente
echo "=== 9. Verificación final ==="
REMAINING=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    echo "⚠️ Aún quedan $REMAINING referencias problemáticas:"
    docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
else
    echo "✅ No quedan referencias problemáticas a from_me"
fi
echo ""

# 10. Reiniciar contenedor
echo "=== 10. Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "⏳ Esperando 25 segundos..."
sleep 25
echo "✅ Completado"
echo ""

echo "=========================================="
echo "📋 INSTRUCCIONES PARA VERIFICAR MENSAJES"
echo "=========================================="
echo ""
echo "Para verificar si Supabase tiene mensajes guardados:"
echo ""
echo "1. Ve a tu panel de Supabase: https://supabase.com/dashboard"
echo "2. Selecciona tu proyecto"
echo "3. Ve a 'Table Editor' → 'whatsapp_messages'"
echo "4. Verifica si hay registros"
echo "5. Si hay registros, verifica que el campo 'chat_id' coincida con los IDs de los chats"
echo ""
echo "También puedes ejecutar esta consulta SQL en Supabase:"
echo ""
echo "SELECT COUNT(*) as total_mensajes, chat_id"
echo "FROM whatsapp_messages"
echo "GROUP BY chat_id"
echo "ORDER BY total_mensajes DESC"
echo "LIMIT 10;"
echo ""


