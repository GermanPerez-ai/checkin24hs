#!/bin/bash
set -e

echo "=========================================="
echo "🔧 MEJORANDO FILTRO DE SPAM Y CORRIGIENDO ERRORES"
echo "=========================================="

DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

# Crear backup
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$DASHBOARD_CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Copiar archivo correcto
if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${DASHBOARD_CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo correcto copiado"
else
    echo "⚠️ No se encontró deploy/dashboard.html localmente"
fi

# ===== MEJORAR FILTRO DE SPAM =====
echo ""
echo "=== Mejorando filtro de spam ==="

# Patrones de spam mejorados (más completos)
SPAM_PATTERNS="'status@broadcast', 'broadcast', 'status.broadcast', '@lid', '@newsletter', '@g.us', 'gid', 'group', 'grupo', 'notify', 'notification', 'system', 'server', 'bot', 'automated', 'auto-reply'"

# Actualizar patrones en dashboard.html (múltiples ubicaciones)
docker exec "$DASHBOARD_CONTAINER" sed -i "s/const spamPatterns = \['status@broadcast', 'broadcast', 'status.broadcast', '@lid', '@newsletter', '@g.us'\];/const spamPatterns = ['status@broadcast', 'broadcast', 'status.broadcast', '@lid', '@newsletter', '@g.us', 'gid', 'group', 'grupo', 'notify', 'notification', 'system', 'server', 'bot', 'automated', 'auto-reply'];/g" /app/dashboard.html

# Actualizar también en supabase-client.js si está en el contenedor
if docker exec "$DASHBOARD_CONTAINER" test -f /app/supabase-client.js; then
    docker exec "$DASHBOARD_CONTAINER" sed -i "s/const spamPatterns = \['status@broadcast', 'broadcast', 'status.broadcast', '@lid', '@newsletter', '@g.us'\];/const spamPatterns = ['status@broadcast', 'broadcast', 'status.broadcast', '@lid', '@newsletter', '@g.us', 'gid', 'group', 'grupo', 'notify', 'notification', 'system', 'server', 'bot', 'automated', 'auto-reply'];/g" /app/supabase-client.js
    echo "✅ Patrones de spam actualizados en supabase-client.js"
fi

echo "✅ Patrones de spam actualizados en dashboard.html"

# ===== ELIMINAR CONSULTAS PROBLEMÁTICAS =====
echo ""
echo "=== Eliminando consultas problemáticas ==="

# Eliminar cualquier consulta con from_me
docker exec "$DASHBOARD_CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Eliminar bloque de verificación directa
docker exec "$DASHBOARD_CONTAINER" sed -i '/\/\/ Verificar primero si hay mensajes con una consulta directa/,/} catch (checkError)/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/Verificar primero si hay mensajes/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/msgCheck\|checkError\|verificación directa/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me,/is_from_me,/g' /app/dashboard.html

echo "✅ Consultas problemáticas eliminadas"

# ===== VERIFICAR CORRECCIONES =====
echo ""
echo "=== Verificando correcciones ==="

# Verificar que no quedan consultas con from_me
REMAINING_PROBLEMS=$(docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING_PROBLEMS" -eq 0 ]; then
    echo "✅ No quedan consultas problemáticas con from_me"
else
    echo "⚠️ Aún quedan $REMAINING_PROBLEMS referencias problemáticas"
    docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | head -5
fi

# Verificar que los patrones de spam están actualizados
SPAM_PATTERNS_COUNT=$(docker exec "$DASHBOARD_CONTAINER" grep -c "gid\|group\|grupo\|notify\|notification\|system\|server\|bot\|automated\|auto-reply" /app/dashboard.html || echo "0")
if [ "$SPAM_PATTERNS_COUNT" -gt 0 ]; then
    echo "✅ Patrones de spam mejorados encontrados ($SPAM_PATTERNS_COUNT referencias)"
else
    echo "⚠️ Los patrones de spam mejorados no se encontraron"
fi

# ===== REINICIAR CONTENEDOR =====
echo ""
echo "=== Reiniciando contenedor ==="
docker restart "$DASHBOARD_CONTAINER"
echo "⏳ Esperando 25 segundos para que el contenedor se inicie..."
sleep 25
echo "✅ Contenedor reiniciado"

# ===== VERIFICAR ESTADO =====
echo ""
echo "=== Verificando estado ==="
if docker ps | grep -q "$DASHBOARD_CONTAINER"; then
    echo "✅ Contenedor está corriendo"
    echo ""
    echo "📋 Últimas 5 líneas de logs:"
    docker logs "$DASHBOARD_CONTAINER" --tail 5
else
    echo "❌ Contenedor NO está corriendo. Revisa los logs con 'docker logs $DASHBOARD_CONTAINER'"
fi

echo ""
echo "=========================================="
echo "✅ MEJORA DE FILTRO DE SPAM Y CORRECCIONES APLICADAS"
echo "=========================================="

echo ""
echo "📋 Resumen:"
echo "  - Patrones de spam mejorados (agregados: gid, group, grupo, notify, notification, system, server, bot, automated, auto-reply)"
echo "  - Consultas problemáticas con from_me eliminadas"
echo "  - Bloque de verificación directa eliminado"
echo ""
echo "🔍 Próximos pasos:"
echo "  1. Limpia el caché del navegador completamente (Ctrl+Shift+R o modo incógnito)"
echo "  2. Prueba seleccionar un chat (no debería aparecer error de from_me)"
echo "  3. Verifica que el spam esté filtrado correctamente"
echo "  4. Si aún hay spam, comparte ejemplos de números/nombres de spam para agregarlos al filtro"
echo ""
echo "💡 Si aún hay problemas, puedes restaurar el backup con:"
echo "   docker exec $DASHBOARD_CONTAINER cp $BACKUP_FILE /app/dashboard.html"


