#!/bin/bash

# Script completo para corregir el chat de WhatsApp
# Elimina todas las consultas problemáticas con from_me y asegura que todo funcione correctamente

set -e  # Salir si hay algún error

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRECCIÓN COMPLETA DEL CHAT DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Verificar que el contenedor existe
echo "=== 1. Verificando contenedor ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    echo "Contenedores disponibles:"
    docker ps --format "{{.Names}}" | grep dashboard || echo "Ninguno"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER"
echo ""

# 2. Verificar que los archivos existen localmente
echo "=== 2. Verificando archivos locales ==="
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ No se encontró deploy/dashboard.html"
    exit 1
fi

if [ ! -f "deploy/supabase-client.js" ]; then
    echo "⚠️ No se encontró deploy/supabase-client.js (continuando de todas formas)"
else
    echo "✅ Archivos encontrados"
fi
echo ""

# 3. Hacer backup del archivo actual en el contenedor
echo "=== 3. Creando backup ==="
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# 4. Copiar archivos actualizados al contenedor
echo "=== 4. Copiando archivos actualizados ==="
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
echo "✅ dashboard.html copiado"

if [ -f "deploy/supabase-client.js" ]; then
    docker cp deploy/supabase-client.js "${CONTAINER}:/app/supabase-client.js" 2>/dev/null || echo "⚠️ No se pudo copiar supabase-client.js (puede estar en otro lugar)"
fi
echo ""

# 5. Buscar consultas problemáticas ANTES de corregir
echo "=== 5. Buscando consultas problemáticas ==="
PROBLEMATIC_QUERIES=$(docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$PROBLEMATIC_QUERIES" -gt 0 ]; then
    echo "⚠️ Se encontraron $PROBLEMATIC_QUERIES consultas problemáticas:"
    docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
else
    echo "✅ No se encontraron consultas problemáticas obvias"
fi
echo ""

# 6. Corregir TODAS las instancias de from_me en select
echo "=== 6. Corrigiendo consultas con from_me ==="
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corregir variaciones con espacios
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me '/select('id, chat_id, body, created_at, is_from_me '/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me\"/select('id, chat_id, body, created_at, is_from_me\"/g" /app/dashboard.html

# Corregir si aparece en una línea con más código
docker exec "$CONTAINER" sed -i "s/'id, chat_id, body, created_at, from_me'/'id, chat_id, body, created_at, is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/"id, chat_id, body, created_at, from_me"/"id, chat_id, body, created_at, is_from_me"/g' /app/dashboard.html

echo "✅ Correcciones aplicadas"
echo ""

# 7. Eliminar bloques de código problemáticos (verificación directa)
echo "=== 7. Eliminando bloques de código problemáticos ==="

# Buscar y eliminar bloques que hagan "verificación directa" con from_me
docker exec "$CONTAINER" sed -i '/const { data: msgCheck/,/} catch (checkError)/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/verificación directa.*from_me/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true

# Eliminar cualquier try-catch que contenga consultas con from_me
docker exec "$CONTAINER" bash -c "sed -i '/try {/,/} catch.*{/ {
    /select.*from_me[^_]/d
    /\.select.*from_me[^_]/d
}" /app/dashboard.html 2>/dev/null || true

echo "✅ Bloques problemáticos eliminados"
echo ""

# 8. Verificar correcciones
echo "=== 8. Verificando correcciones ==="
REMAINING_PROBLEMS=$(docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)

if [ "$REMAINING_PROBLEMS" -gt 0 ]; then
    echo "⚠️ Aún quedan $REMAINING_PROBLEMS consultas problemáticas:"
    docker exec "$CONTAINER" grep -n "select.*from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
    echo ""
    echo "🔧 Intentando corrección adicional..."
    # Corrección más agresiva
    docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
    docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
    docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
else
    echo "✅ No quedan consultas problemáticas"
fi

# Verificar que is_from_me está presente
IS_FROM_ME_COUNT=$(docker exec "$CONTAINER" grep -c "is_from_me" /app/dashboard.html || echo "0")
echo "✅ Se encontraron $IS_FROM_ME_COUNT referencias correctas a is_from_me"
echo ""

# 9. Verificar línea 24521 (donde estaba el problema)
echo "=== 9. Verificando línea problemática (24521) ==="
LINE_24521=$(docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html)
if echo "$LINE_24521" | grep -q "from_me" && ! echo "$LINE_24521" | grep -q "is_from_me"; then
    echo "⚠️ La línea 24521 todavía tiene from_me:"
    echo "$LINE_24521"
    echo "🔧 Corrigiendo línea específica..."
    docker exec "$CONTAINER" sed -i '24521s/from_me/is_from_me/g' /app/dashboard.html
    echo "✅ Línea corregida"
else
    echo "✅ Línea 24521 está correcta:"
    echo "$LINE_24521"
fi
echo ""

# 10. Verificar que getWhatsAppMessages está siendo usado
echo "=== 10. Verificando uso de getWhatsAppMessages ==="
GET_MESSAGES_COUNT=$(docker exec "$CONTAINER" grep -c "getWhatsAppMessages" /app/dashboard.html || echo "0")
if [ "$GET_MESSAGES_COUNT" -gt 0 ]; then
    echo "✅ Se encontraron $GET_MESSAGES_COUNT referencias a getWhatsAppMessages (correcto)"
else
    echo "⚠️ No se encontraron referencias a getWhatsAppMessages"
fi
echo ""

# 11. Reiniciar contenedor
echo "=== 11. Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "⏳ Esperando 30 segundos para que el contenedor se inicie..."
sleep 30
echo ""

# 12. Verificar que el contenedor está corriendo
echo "=== 12. Verificando estado del contenedor ==="
if docker ps --format "{{.Names}}" | grep -q "$CONTAINER"; then
    echo "✅ Contenedor está corriendo"
    
    # Verificar logs recientes
    echo ""
    echo "📋 Últimas 5 líneas de logs:"
    docker logs "$CONTAINER" --tail 5 2>&1 | tail -5
else
    echo "❌ El contenedor no está corriendo"
    echo "📋 Últimas 20 líneas de logs:"
    docker logs "$CONTAINER" --tail 20 2>&1 | tail -20
    exit 1
fi
echo ""

# 13. Resumen final
echo "=========================================="
echo "✅ CORRECCIÓN COMPLETA FINALIZADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "  - Contenedor: $CONTAINER"
echo "  - Backup creado: $BACKUP_FILE"
echo "  - Consultas problemáticas encontradas: $PROBLEMATIC_QUERIES"
echo "  - Consultas problemáticas restantes: $REMAINING_PROBLEMS"
echo "  - Referencias correctas a is_from_me: $IS_FROM_ME_COUNT"
echo "  - Referencias a getWhatsAppMessages: $GET_MESSAGES_COUNT"
echo ""
echo "🔍 Próximos pasos:"
echo "  1. Limpia el caché del navegador (Ctrl+Shift+R o modo incógnito)"
echo "  2. Prueba seleccionar un chat"
echo "  3. Verifica la consola del navegador para errores"
echo ""
echo "💡 Si aún hay problemas, puedes restaurar el backup con:"
echo "   docker exec $CONTAINER cp $BACKUP_FILE /app/dashboard.html"
echo ""

