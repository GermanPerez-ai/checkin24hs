#!/bin/bash
# Script simple para actualizar dashboard.html directamente desde GitHub

echo "🔧 ACTUALIZANDO DASHBOARD DESDE GITHUB"
echo "======================================"
echo ""

# Buscar contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor dashboard"
    echo "Buscando todos los contenedores..."
    docker ps | grep -i dashboard
    exit 1
fi

CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER" --format "{{.Names}}")
echo "✅ Contenedor encontrado: $CONTAINER_NAME"
echo ""

# Crear backup
echo "💾 Creando backup del archivo actual..."
BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec $CONTAINER cp /app/dashboard.html /app/$BACKUP_NAME 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_NAME"
echo ""

# Descargar archivo nuevo
echo "📥 Descargando dashboard.html desde GitHub..."
curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html -o /tmp/dashboard_new.html

if [ ! -f /tmp/dashboard_new.html ] || [ ! -s /tmp/dashboard_new.html ]; then
    echo "❌ Error al descargar desde GitHub"
    exit 1
fi

FILE_SIZE=$(wc -c < /tmp/dashboard_new.html)
echo "✅ Archivo descargado: $FILE_SIZE bytes"
echo ""

# Verificar cambios en el archivo descargado
echo "🔍 Verificando que el archivo tiene los cambios necesarios..."
HAS_ASYNC=$(grep -c "saveWhatsAppConfig = async function" /tmp/dashboard_new.html || echo "0")
HAS_SUPABASE=$(grep -A 20 "saveWhatsAppConfig = async function" /tmp/dashboard_new.html | grep -c "system_config" || echo "0")
HAS_VERSION=$(grep -c "VERSIÓN ACTUALIZADA de loadExpensesData" /tmp/dashboard_new.html || echo "0")

if [ "$HAS_ASYNC" -gt "0" ]; then
    echo "✅ Tiene saveWhatsAppConfig con async function"
    if [ "$HAS_SUPABASE" -gt "0" ]; then
        echo "✅ Tiene código de Supabase en saveWhatsAppConfig"
    else
        echo "⚠️ No tiene código de Supabase en saveWhatsAppConfig"
    fi
else
    echo "❌ No tiene saveWhatsAppConfig con async function"
    exit 1
fi

if [ "$HAS_VERSION" -gt "0" ]; then
    echo "✅ Tiene VERSIÓN ACTUALIZADA de loadExpensesData"
else
    echo "⚠️ No tiene VERSIÓN ACTUALIZADA de loadExpensesData"
fi

echo ""

# Copiar al contenedor
echo "📋 Copiando archivo al contenedor..."
docker cp /tmp/dashboard_new.html $CONTAINER:/app/dashboard.html

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar archivo al contenedor"
    rm -f /tmp/dashboard_new.html
    exit 1
fi

echo "✅ Archivo copiado correctamente"
echo ""

# Verificar que se copió correctamente
echo "🔍 Verificando cambios en el contenedor..."
VERIFY_SIZE=$(docker exec $CONTAINER stat -c %s /app/dashboard.html 2>/dev/null || echo "0")
echo "Tamaño del archivo en contenedor: $VERIFY_SIZE bytes"

if [ "$VERIFY_SIZE" -lt "1000000" ]; then
    echo "❌ Error: El archivo copiado es muy pequeño"
    rm -f /tmp/dashboard_new.html
    exit 1
fi

# Verificar cambios específicos
echo ""
echo "Verificando cambios específicos..."

if docker exec $CONTAINER grep -q "saveWhatsAppConfig = async function" /app/dashboard.html 2>/dev/null; then
    echo "✅ saveWhatsAppConfig tiene 'async function' en el contenedor"
    
    if docker exec $CONTAINER grep -A 20 "saveWhatsAppConfig = async function" /app/dashboard.html 2>/dev/null | grep -q "system_config"; then
        echo "✅ saveWhatsAppConfig tiene código de Supabase en el contenedor"
    else
        echo "⚠️ saveWhatsAppConfig no tiene código de Supabase completo en el contenedor"
    fi
else
    echo "❌ saveWhatsAppConfig no tiene 'async function' en el contenedor"
fi

if docker exec $CONTAINER grep -q "VERSIÓN ACTUALIZADA de loadExpensesData" /app/dashboard.html 2>/dev/null; then
    echo "✅ loadExpensesData tiene VERSIÓN ACTUALIZADA en el contenedor"
else
    echo "⚠️ loadExpensesData no tiene VERSIÓN ACTUALIZADA en el contenedor"
fi

# Limpiar
rm -f /tmp/dashboard_new.html

echo ""
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Backup creado: $BACKUP_NAME"
echo "   - Archivo nuevo copiado: ✅"
echo "   - Tamaño verificado: $VERIFY_SIZE bytes"
echo ""
echo "🔄 PRÓXIMOS PASOS:"
echo "   1. Recarga el navegador con CACHE FORZADA:"
echo "      - Windows/Linux: Ctrl + Shift + R"
echo "      - Mac: Cmd + Shift + R"
echo "   2. Abre la consola del navegador (F12)"
echo "   3. Deberías ver los logs:"
echo "      '🔍 VERSIÓN ACTUALIZADA de loadExpensesData ejecutándose...'"
echo ""
echo "⚠️ NOTA: Estos cambios son TEMPORALES"
echo "   Se perderán al hacer rebuild del servicio."
echo "   Para hacerlos permanentes, haz rebuild en EasyPanel."
echo ""
