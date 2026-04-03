#!/bin/bash
set -e

echo "=========================================="
echo "🔍 VERIFICANDO MENSAJES EN SUPABASE Y CORRIGIENDO ERROR"
echo "=========================================="

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# PASO 1: Verificar mensajes en Supabase (requiere acceso manual)
echo "=== PASO 1: Verificación de mensajes en Supabase ==="
echo ""
echo "📋 Para verificar si hay mensajes guardados en Supabase:"
echo "   1. Ve a https://supabase.com/dashboard"
echo "   2. Selecciona tu proyecto"
echo "   3. Ve a 'Table Editor' -> 'whatsapp_messages'"
echo "   4. Verifica si hay registros con los chat_id que estás probando:"
echo "      - 9e8d6042-aab6-48a2-a8c9-5ae6fd62fac7"
echo "      - 209683f5-596a-4113-94cb-37e12c01fa80"
echo "      - b6e61d57-bafd-4790-b8f3-f0fe8f11cf86"
echo ""
echo "   Si NO hay mensajes, el problema está en el servidor de WhatsApp que no los está guardando."
echo "   Si SÍ hay mensajes, el problema está en el código del dashboard que no los está cargando."
echo ""

# PASO 2: Buscar el bloque problemático en el servidor
echo "=== PASO 2: Buscando bloque problemático en el servidor ==="
PROBLEM_BLOCK=$(docker exec "$CONTAINER" grep -n "select.*from_me[^_]" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5)
if [ -z "$PROBLEM_BLOCK" ]; then
    echo "✅ No se encontró el bloque problemático con 'from_me'"
else
    echo "❌ SE ENCONTRÓ EL BLOQUE PROBLEMÁTICO:"
    echo "$PROBLEM_BLOCK"
    echo ""
    echo "Mostrando contexto alrededor de las líneas problemáticas:"
    docker exec "$CONTAINER" grep -B 3 -A 3 "select.*from_me[^_]" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -20
fi

# Buscar también el bloque de "verificación directa"
echo ""
echo "=== Buscando bloque de 'verificación directa' ==="
VERIFICATION_BLOCK=$(docker exec "$CONTAINER" grep -n "verificación directa\|Error en verificación directa\|msgCheck\|checkError" /app/dashboard.html | head -10)
if [ -z "$VERIFICATION_BLOCK" ]; then
    echo "✅ No se encontró el bloque de verificación directa"
else
    echo "❌ SE ENCONTRÓ EL BLOQUE DE VERIFICACIÓN DIRECTA:"
    echo "$VERIFICATION_BLOCK"
fi

# PASO 3: Crear backup y copiar archivo correcto
echo ""
echo "=== PASO 3: Copiando archivo correcto ==="
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"

if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo correcto copiado desde deploy/dashboard.html"
else
    echo "❌ Error: deploy/dashboard.html no encontrado"
    exit 1
fi

# PASO 4: Eliminar TODAS las líneas problemáticas
echo ""
echo "=== PASO 4: Eliminando líneas problemáticas ==="
docker exec "$CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html
docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html
docker exec "$CONTAINER" sed -i '/const { data: msgCheck/d' /app/dashboard.html
docker exec "$CONTAINER" sed -i '/msgCheck\|checkError/d' /app/dashboard.html
docker exec "$CONTAINER" sed -i '/verificación directa/d' /app/dashboard.html
docker exec "$CONTAINER" sed -i '/Error en verificación directa/d' /app/dashboard.html

# Eliminar bloques try-catch completos
docker exec "$CONTAINER" sed -i '/\/\/ Verificar primero/,/} catch (checkError)/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/Verificar primero/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true

echo "✅ Eliminación completada"

# PASO 5: Verificación final
echo ""
echo "=== PASO 5: Verificación final ==="
FINAL_CHECK=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$FINAL_CHECK" -eq 0 ]; then
    echo "✅ NO quedan consultas problemáticas con from_me"
else
    echo "❌ AÚN QUEDAN $FINAL_CHECK consultas problemáticas:"
    docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -10
fi

# Verificar que getWhatsAppMessages está siendo usado
GET_MESSAGES_COUNT=$(docker exec "$CONTAINER" grep -c "getWhatsAppMessages" /app/dashboard.html || echo "0")
if [ "$GET_MESSAGES_COUNT" -gt 0 ]; then
    echo "✅ getWhatsAppMessages está siendo usado ($GET_MESSAGES_COUNT veces)"
else
    echo "❌ ERROR: getWhatsAppMessages NO está siendo usado"
fi

# PASO 6: Reiniciar contenedor
echo ""
echo "=== PASO 6: Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "⏳ Esperando 30 segundos..."
sleep 30

if docker ps | grep -q "$CONTAINER"; then
    echo "✅ Contenedor está corriendo"
else
    echo "❌ Contenedor NO está corriendo"
fi

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN Y CORRECCIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 RESUMEN:"
echo "  - Consultas problemáticas restantes: $FINAL_CHECK"
echo "  - getWhatsAppMessages usado: $GET_MESSAGES_COUNT veces"
echo ""
echo "🔍 PRÓXIMOS PASOS:"
echo "  1. Verifica en Supabase si hay mensajes guardados (ver instrucciones arriba)"
echo "  2. Si NO hay mensajes: El problema está en whatsapp-server.js que no los guarda"
echo "  3. Si SÍ hay mensajes: Limpia el caché del navegador completamente"
echo "     - Presiona Ctrl+Shift+Delete"
echo "     - Selecciona 'Caché' y 'Datos del sitio'"
echo "     - O usa modo incógnito (Ctrl+Shift+N)"
echo "  4. Cierra TODAS las pestañas del dashboard"
echo "  5. Abre una nueva pestaña en modo incógnito"
echo "  6. Prueba seleccionar un chat"

