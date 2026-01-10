#!/bin/bash
# Script para aplicar cambios directamente descargando desde GitHub

echo "🔧 APLICANDO CAMBIOS DESDE GITHUB"
echo "=================================="
echo ""

# Buscar contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor dashboard"
    docker ps | grep dashboard
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER"
echo ""

# Crear backup
echo "💾 Creando backup..."
docker exec $CONTAINER cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

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

# Verificar que tiene los cambios
echo "🔍 Verificando cambios en el archivo..."
if grep -q "saveWhatsAppConfig = async function" /tmp/dashboard_new.html; then
    echo "✅ El archivo tiene saveWhatsAppConfig con async function"
    if grep -A 20 "saveWhatsAppConfig = async function" /tmp/dashboard_new.html | grep -q "system_config"; then
        echo "✅ El archivo tiene código de Supabase"
    else
        echo "⚠️ El archivo NO tiene código de Supabase"
    fi
else
    echo "❌ El archivo NO tiene los cambios de saveWhatsAppConfig"
    exit 1
fi

# Verificar VERSIÓN ACTUALIZADA
if grep -q "VERSIÓN ACTUALIZADA de loadExpensesData" /tmp/dashboard_new.html; then
    echo "✅ El archivo tiene la VERSIÓN ACTUALIZADA de loadExpensesData"
else
    echo "⚠️ El archivo NO tiene VERSIÓN ACTUALIZADA de loadExpensesData"
fi

echo ""
echo "📋 Copiando archivo al contenedor..."
docker cp /tmp/dashboard_new.html $CONTAINER:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
    
    # Verificar que se copió
    VERIFY_SIZE=$(docker exec $CONTAINER stat -c %s /app/dashboard.html 2>/dev/null || echo "0")
    echo "   Tamaño en contenedor: $VERIFY_SIZE bytes"
    
    if [ "$VERIFY_SIZE" -gt "1000000" ]; then
        echo "✅ Archivo verificado correctamente"
        echo ""
        echo "🔍 Verificando cambios aplicados en el contenedor..."
        
        if docker exec $CONTAINER grep -q "saveWhatsAppConfig = async function" /app/dashboard.html; then
            echo "✅ saveWhatsAppConfig tiene 'async function'"
            if docker exec $CONTAINER grep -A 20 "saveWhatsAppConfig = async function" /app/dashboard.html | grep -q "system_config"; then
                echo "✅ saveWhatsAppConfig tiene código de Supabase"
                echo ""
                echo "✅✅✅ CAMBIOS APLICADOS CORRECTAMENTE ✅✅✅"
            else
                echo "⚠️ saveWhatsAppConfig no tiene código de Supabase completo"
            fi
        else
            echo "❌ saveWhatsAppConfig aún no tiene los cambios"
        fi
        
        # Verificar loadExpensesData
        if docker exec $CONTAINER grep -q "VERSIÓN ACTUALIZADA de loadExpensesData" /app/dashboard.html; then
            echo "✅ loadExpensesData tiene VERSIÓN ACTUALIZADA"
        else
            echo "⚠️ loadExpensesData aún no tiene VERSIÓN ACTUALIZADA"
        fi
    else
        echo "❌ Error: El archivo copiado no tiene el tamaño correcto"
    fi
else
    echo "❌ Error al copiar archivo al contenedor"
    exit 1
fi

rm -f /tmp/dashboard_new.html

echo ""
echo "=========================================="
echo "⚠️ IMPORTANTE:"
echo "=========================================="
echo "Los cambios aplicados son TEMPORALES"
echo "Se perderán al hacer rebuild del servicio"
echo ""
echo "Para hacer los cambios PERMANENTES:"
echo "1. Ve a EasyPanel → Servicios → dashboard"
echo "2. Haz clic en 'Rebuild' o 'Deploy'"
echo "3. Asegúrate que esté configurado para usar GitHub"
echo ""
