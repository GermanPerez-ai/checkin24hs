#!/bin/bash
set -e

echo "=========================================="
echo "🗑️ ELIMINANDO BLOQUE DE VERIFICACIÓN DIRECTA"
echo "=========================================="

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Crear backup
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Copiar archivo correcto primero
if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo correcto copiado desde deploy/dashboard.html"
else
    echo "⚠️ No se encontró deploy/dashboard.html localmente"
fi

# Buscar y mostrar el bloque problemático ANTES de eliminarlo
echo ""
echo "=== Buscando bloque de verificación directa ==="
VERIFICATION_BLOCK=$(docker exec "$CONTAINER" grep -n "Verificar primero\|verificación directa\|msgCheck\|checkError" /app/dashboard.html | head -10)
if [ -z "$VERIFICATION_BLOCK" ]; then
    echo "✅ No se encontró bloque de verificación directa"
else
    echo "⚠️ Se encontró bloque de verificación directa:"
    echo "$VERIFICATION_BLOCK"
fi

# Buscar la consulta problemática específica
echo ""
echo "=== Buscando consulta con from_me ==="
FROM_ME_QUERY=$(docker exec "$CONTAINER" grep -n "select.*from_me[^_]" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5)
if [ -z "$FROM_ME_QUERY" ]; then
    echo "✅ No se encontraron consultas con from_me"
else
    echo "❌ Se encontraron consultas problemáticas:"
    echo "$FROM_ME_QUERY"
fi

# Eliminar el bloque completo de verificación directa usando múltiples métodos
echo ""
echo "=== Eliminando bloque de verificación directa ==="

# Método 1: Eliminar líneas que contengan la consulta problemática
docker exec "$CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Método 2: Eliminar el bloque try-catch completo de verificación directa
# Buscar desde "Verificar primero" hasta el catch correspondiente
docker exec "$CONTAINER" sed -i '/\/\/ Verificar primero/,/} catch (checkError)/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/Verificar primero/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true

# Método 3: Eliminar líneas relacionadas con msgCheck y checkError
docker exec "$CONTAINER" sed -i '/const { data: msgCheck/d' /app/dashboard.html 2>/dev/null || true
docker exec "$CONTAINER" sed -i '/msgCheck\|checkError/d' /app/dashboard.html 2>/dev/null || true

# Método 4: Eliminar cualquier línea que contenga "verificación directa"
docker exec "$CONTAINER" sed -i '/verificación directa/d' /app/dashboard.html 2>/dev/null || true

# Método 5: Buscar y eliminar el bloque completo usando contexto
# Buscar desde "Buscando mensajes" hasta antes de "getWhatsAppMessages"
docker exec "$CONTAINER" sed -i '/🔍 Buscando mensajes para chat_id/,/getWhatsAppMessages/{/getWhatsAppMessages/!d}' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante
docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/from_me,/is_from_me,/g' /app/dashboard.html

echo "✅ Eliminación completada"

# Verificar que se eliminó
echo ""
echo "=== Verificando eliminación ==="
REMAINING_VERIFICATION=$(docker exec "$CONTAINER" grep -n "verificación directa\|msgCheck\|checkError" /app/dashboard.html | head -5)
if [ -z "$REMAINING_VERIFICATION" ]; then
    echo "✅ Bloque de verificación directa eliminado completamente"
else
    echo "⚠️ Aún quedan referencias:"
    echo "$REMAINING_VERIFICATION"
fi

REMAINING_FROM_ME=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5)
if [ -z "$REMAINING_FROM_ME" ]; then
    echo "✅ No quedan consultas con from_me"
else
    echo "❌ AÚN QUEDAN CONSULTAS CON from_me:"
    echo "$REMAINING_FROM_ME"
fi

# Verificar que getWhatsAppMessages está siendo usado
echo ""
echo "=== Verificando uso de getWhatsAppMessages ==="
GET_MESSAGES_USAGE=$(docker exec "$CONTAINER" grep -n "getWhatsAppMessages" /app/dashboard.html | head -5)
if [ -z "$GET_MESSAGES_USAGE" ]; then
    echo "❌ No se encontró uso de getWhatsAppMessages"
else
    echo "✅ getWhatsAppMessages está siendo usado:"
    echo "$GET_MESSAGES_USAGE"
fi

# Reiniciar contenedor
echo ""
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "⏳ Esperando 30 segundos..."
sleep 30
echo "✅ Contenedor reiniciado"

echo ""
echo "=========================================="
echo "✅ ELIMINACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "  1. Limpia el caché del navegador completamente (Ctrl+Shift+R)"
echo "  2. Prueba seleccionar un chat"
echo "  3. Verifica que no aparezca el error de from_me"
echo ""
echo "💡 Si aún hay problemas, puedes restaurar el backup con:"
echo "   docker exec $CONTAINER cp $BACKUP_FILE /app/dashboard.html"


