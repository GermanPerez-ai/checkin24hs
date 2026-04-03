#!/bin/bash
# Script para verificar y aplicar cambios directamente con diagnóstico

echo "🔧 VERIFICANDO Y APLICANDO CAMBIOS DIRECTAMENTE"
echo "==============================================="
echo ""

# 1. Buscar contenedor
echo "1️⃣ Buscando contenedor..."
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor dashboard"
    echo "Buscando todos los contenedores..."
    docker ps | grep -i dashboard
    exit 1
fi

CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER" --format "{{.Names}}")
echo "✅ Contenedor: $CONTAINER_NAME ($CONTAINER)"
echo ""

# 2. Verificar archivo actual
echo "2️⃣ Verificando archivo actual en el contenedor..."
DASHBOARD_FILE="/app/dashboard.html"

# Verificar si el archivo existe
if docker exec $CONTAINER test -f "$DASHBOARD_FILE"; then
    echo "✅ Archivo existe: $DASHBOARD_FILE"
    CURRENT_SIZE=$(docker exec $CONTAINER stat -c %s "$DASHBOARD_FILE" 2>/dev/null || echo "0")
    echo "   Tamaño actual: $CURRENT_SIZE bytes"
    
    # Verificar versión actual
    CURRENT_VERSION=$(docker exec $CONTAINER grep -c "VERSIÓN ACTUALIZADA de loadExpensesData" "$DASHBOARD_FILE" 2>/dev/null || echo "0")
    if [ "$CURRENT_VERSION" -gt "0" ]; then
        echo "✅ Ya tiene VERSIÓN ACTUALIZADA"
        HAS_VERSION=true
    else
        echo "❌ NO tiene VERSIÓN ACTUALIZADA (versión antigua)"
        HAS_VERSION=false
    fi
else
    echo "⚠️ Archivo no encontrado en /app/dashboard.html"
    echo "Buscando en otras ubicaciones..."
    docker exec $CONTAINER find / -name "dashboard.html" -type f 2>/dev/null | head -5
    read -p "Ingresa la ruta completa del archivo (o Enter para usar /app/dashboard.html): " DASHBOARD_FILE
    DASHBOARD_FILE=${DASHBOARD_FILE:-/app/dashboard.html}
    HAS_VERSION=false
fi
echo ""

# 3. Descargar archivo nuevo desde GitHub
echo "3️⃣ Descargando dashboard.html desde GitHub..."
curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html -o /tmp/dashboard_new.html

if [ ! -f /tmp/dashboard_new.html ] || [ ! -s /tmp/dashboard_new.html ]; then
    echo "❌ Error al descargar desde GitHub"
    echo "Verificando conectividad..."
    curl -I https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html | head -3
    exit 1
fi

NEW_SIZE=$(wc -c < /tmp/dashboard_new.html)
echo "✅ Archivo descargado: $NEW_SIZE bytes"
echo ""

# 4. Verificar que el archivo descargado tiene los cambios
echo "4️⃣ Verificando cambios en el archivo descargado..."
HAS_ASYNC=$(grep -c "saveWhatsAppConfig = async function" /tmp/dashboard_new.html || echo "0")
HAS_SUPABASE=$(grep -A 20 "saveWhatsAppConfig = async function" /tmp/dashboard_new.html | grep -c "system_config" || echo "0")
HAS_VERSION_NEW=$(grep -c "VERSIÓN ACTUALIZADA de loadExpensesData" /tmp/dashboard_new.html || echo "0")

echo "   - saveWhatsAppConfig con async: $HAS_ASYNC"
echo "   - Código de Supabase: $HAS_SUPABASE"
echo "   - VERSIÓN ACTUALIZADA: $HAS_VERSION_NEW"

if [ "$HAS_VERSION_NEW" -eq "0" ]; then
    echo ""
    echo "⚠️ ADVERTENCIA: El archivo descargado NO tiene VERSIÓN ACTUALIZADA"
    echo "   Esto puede significar que GitHub no tiene el código actualizado"
    echo "   Verificando último commit en GitHub..."
    curl -s https://api.github.com/repos/GermanPerez-ai/checkin24hs/commits/main | grep -o '"message":"[^"]*' | head -1
    echo ""
    read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        rm -f /tmp/dashboard_new.html
        exit 1
    fi
fi
echo ""

# 5. Crear backup
if [ "$HAS_VERSION" = "false" ]; then
    echo "5️⃣ Creando backup del archivo actual..."
    BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec $CONTAINER cp "$DASHBOARD_FILE" "/app/$BACKUP_NAME" 2>/dev/null || true
    echo "✅ Backup: $BACKUP_NAME"
    echo ""
    
    # 6. Copiar archivo nuevo
    echo "6️⃣ Copiando archivo nuevo al contenedor..."
    docker cp /tmp/dashboard_new.html "$CONTAINER:$DASHBOARD_FILE"
    
    if [ $? -ne 0 ]; then
        echo "❌ Error al copiar archivo"
        rm -f /tmp/dashboard_new.html
        exit 1
    fi
    
    echo "✅ Archivo copiado"
    echo ""
    
    # 7. Verificar que se copió correctamente
    echo "7️⃣ Verificando que los cambios se aplicaron..."
    sleep 2
    
    VERIFY_SIZE=$(docker exec $CONTAINER stat -c %s "$DASHBOARD_FILE" 2>/dev/null || echo "0")
    echo "   Tamaño verificado: $VERIFY_SIZE bytes"
    
    VERIFY_VERSION=$(docker exec $CONTAINER grep -c "VERSIÓN ACTUALIZADA de loadExpensesData" "$DASHBOARD_FILE" 2>/dev/null || echo "0")
    echo "   VERSIÓN ACTUALIZADA encontrada: $VERIFY_VERSION"
    
    VERIFY_ASYNC=$(docker exec $CONTAINER grep -c "saveWhatsAppConfig = async function" "$DASHBOARD_FILE" 2>/dev/null || echo "0")
    echo "   saveWhatsAppConfig async: $VERIFY_ASYNC"
    
    if [ "$VERIFY_VERSION" -gt "0" ] && [ "$VERIFY_SIZE" -gt "1000000" ]; then
        echo ""
        echo "✅✅✅ CAMBIOS APLICADOS CORRECTAMENTE ✅✅✅"
    else
        echo ""
        echo "❌ Los cambios NO se aplicaron correctamente"
        echo "   Verificando contenido del archivo..."
        docker exec $CONTAINER head -20 "$DASHBOARD_FILE"
    fi
else
    echo "5️⃣ El archivo ya tiene VERSIÓN ACTUALIZADA, no es necesario actualizar"
    echo "   Pero verificando si tiene todos los cambios..."
    
    VERIFY_SUPABASE=$(docker exec $CONTAINER grep -A 20 "saveWhatsAppConfig = async function" "$DASHBOARD_FILE" 2>/dev/null | grep -c "system_config" || echo "0")
    if [ "$VERIFY_SUPABASE" -eq "0" ]; then
        echo "⚠️ Falta código de Supabase, aplicando cambios..."
        docker cp /tmp/dashboard_new.html "$CONTAINER:$DASHBOARD_FILE"
        echo "✅ Cambios aplicados"
    fi
fi

# Limpiar
rm -f /tmp/dashboard_new.html

echo ""
echo "=========================================="
echo "📋 VERIFICACIÓN FINAL"
echo "=========================================="
echo ""
echo "Ejecuta este comando para verificar:"
echo "  docker exec $CONTAINER grep -c 'VERSIÓN ACTUALIZADA de loadExpensesData' $DASHBOARD_FILE"
echo ""
echo "Debería devolver un número mayor a 0"
echo ""
