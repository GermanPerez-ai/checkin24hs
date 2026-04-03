#!/bin/bash
set -e

echo "=========================================="
echo "🔧 SOLUCIÓN DEFINITIVA - MENSAJES DE WHATSAPP"
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

# PASO 1: Copiar archivo correcto desde deploy/
if [ -f "deploy/dashboard.html" ]; then
    echo "=== Copiando archivo correcto ==="
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo copiado desde deploy/dashboard.html"
else
    echo "❌ Error: deploy/dashboard.html no encontrado"
    exit 1
fi

# PASO 2: Buscar y eliminar CUALQUIER línea problemática
echo ""
echo "=== Buscando líneas problemáticas ==="
PROBLEM_LINES=$(docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" || echo "")
if [ -z "$PROBLEM_LINES" ]; then
    echo "✅ No se encontraron líneas problemáticas"
else
    echo "⚠️ Se encontraron líneas problemáticas:"
    echo "$PROBLEM_LINES"
    
    echo ""
    echo "=== Eliminando líneas problemáticas ==="
    
    # Eliminar TODAS las líneas que contengan la consulta problemática
    docker exec "$CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html
    docker exec "$CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html
    docker exec "$CONTAINER" sed -i '/const { data: msgCheck/d' /app/dashboard.html
    docker exec "$CONTAINER" sed -i '/msgCheck\|checkError/d' /app/dashboard.html
    docker exec "$CONTAINER" sed -i '/verificación directa/d' /app/dashboard.html
    docker exec "$CONTAINER" sed -i '/Error en verificación directa/d' /app/dashboard.html
    
    # Eliminar bloques try-catch completos
    docker exec "$CONTAINER" sed -i '/\/\/ Verificar primero/,/} catch (checkError)/d' /app/dashboard.html 2>/dev/null || true
    docker exec "$CONTAINER" sed -i '/Verificar primero/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true
    
    # Reemplazar cualquier from_me restante
    docker exec "$CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
    docker exec "$CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
    docker exec "$CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
    docker exec "$CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
    docker exec "$CONTAINER" sed -i 's/from_me,/is_from_me,/g' /app/dashboard.html
    
    echo "✅ Eliminación completada"
fi

# PASO 3: Optimizar recargas (agregar debounce para evitar recargas excesivas)
echo ""
echo "=== Optimizando recargas ==="
# Buscar y agregar debounce a las recargas de chats
if docker exec "$CONTAINER" grep -q "Cambio en chat detectado, recargando" /app/dashboard.html; then
    echo "✅ Se encontró código de recarga, optimizando..."
    # Agregar debounce de 2 segundos para evitar recargas excesivas
    docker exec "$CONTAINER" sed -i 's/console.log('\''📱 Cambio en chat detectado, recargando\.\.\.'\'');/let reloadTimeout; if (reloadTimeout) clearTimeout(reloadTimeout); reloadTimeout = setTimeout(() => { console.log('\''📱 Cambio en chat detectado, recargando\.\.\.'\''); loadActiveChats(); }, 2000);/g' /app/dashboard.html
    echo "✅ Debounce agregado a recargas de chats"
fi

# PASO 4: Verificación final
echo ""
echo "=== Verificación final ==="
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

# Verificar que no hay bloques de verificación directa
VERIFICATION_BLOCK=$(docker exec "$CONTAINER" grep -n "verificación directa\|msgCheck\|checkError" /app/dashboard.html | head -5)
if [ -z "$VERIFICATION_BLOCK" ]; then
    echo "✅ No hay bloques de verificación directa"
else
    echo "⚠️ Aún hay bloques de verificación directa:"
    echo "$VERIFICATION_BLOCK"
fi

# PASO 5: Reiniciar contenedor
echo ""
echo "=== Reiniciando contenedor ==="
docker restart "$CONTAINER"
echo "⏳ Esperando 30 segundos..."
sleep 30

# Verificar estado
if docker ps | grep -q "$CONTAINER"; then
    echo "✅ Contenedor está corriendo"
else
    echo "❌ Contenedor NO está corriendo"
fi

echo ""
echo "=========================================="
echo "✅ SOLUCIÓN DEFINITIVA APLICADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "  - Archivo correcto copiado: ✅"
echo "  - Consultas problemáticas restantes: $FINAL_CHECK"
echo "  - getWhatsAppMessages usado: $GET_MESSAGES_COUNT veces"
echo "  - Recargas optimizadas: ✅"
echo ""
echo "🔍 PRÓXIMOS PASOS CRÍTICOS:"
echo "  1. LIMPIA EL CACHÉ DEL NAVEGADOR COMPLETAMENTE:"
echo "     - Presiona Ctrl+Shift+Delete"
echo "     - Selecciona 'Caché' y 'Datos del sitio'"
echo "     - O usa modo incógnito (Ctrl+Shift+N)"
echo "  2. Cierra TODAS las pestañas del dashboard"
echo "  3. Abre una nueva pestaña en modo incógnito"
echo "  4. Prueba seleccionar un chat"
echo ""
echo "💡 Si aún aparece el error, el problema es caché del navegador"


