#!/bin/bash
# Script para verificar y actualizar el dashboard con los cambios de base de conocimiento

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICANDO Y ACTUALIZANDO BASE DE CONOCIMIENTO"
echo "=========================================="
echo ""

# 1. Verificar que el archivo local tiene los cambios
echo "1️⃣ Verificando archivo local..."
if grep -q "Cargando hoteles para selector (knowledge/policies)" deploy/dashboard.html 2>/dev/null; then
    echo "✅ Archivo local tiene los cambios"
else
    echo "❌ Archivo local NO tiene los cambios"
    echo "   Necesitas subir el archivo desde tu máquina Windows"
    exit 1
fi

# 2. Buscar contenedor
echo ""
echo "2️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"

# 3. Buscar ruta del dashboard en el contenedor
echo ""
echo "3️⃣ Buscando ruta del dashboard en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
)

DASHBOARD_PATH=""
for path in "${DASHBOARD_PATHS[@]}"; do
    if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
        DASHBOARD_PATH="$path"
        echo "✅ Encontrado en: $path"
        break
    fi
done

if [ -z "$DASHBOARD_PATH" ]; then
    echo "⚠️ No se encontró, usando /app/dashboard.html"
    DASHBOARD_PATH="/app/dashboard.html"
fi

# 4. Verificar versión actual en el contenedor
echo ""
echo "4️⃣ Verificando versión en el contenedor..."
if docker exec "$CONTAINER_ID" grep -q "Cargando hoteles para selector (knowledge/policies)" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Contenedor tiene la versión actualizada"
    NEEDS_UPDATE=false
else
    echo "❌ Contenedor NO tiene la versión actualizada"
    NEEDS_UPDATE=true
fi

# 5. Verificar función loadSelectedHotelKnowledge
echo ""
echo "5️⃣ Verificando función loadSelectedHotelKnowledge..."
if docker exec "$CONTAINER_ID" grep -q "async function loadSelectedHotelKnowledge\|window.loadSelectedHotelKnowledge = async function" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Función es asíncrona (versión nueva)"
else
    echo "❌ Función NO es asíncrona (versión antigua)"
    NEEDS_UPDATE=true
fi

# 6. Actualizar si es necesario
if [ "$NEEDS_UPDATE" = true ]; then
    echo ""
    echo "6️⃣ Actualizando archivo en el contenedor..."
    
    # Hacer backup
    BACKUP_PATH="${DASHBOARD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "$BACKUP_PATH" 2>/dev/null
    echo "✅ Backup creado: $BACKUP_PATH"
    
    # Copiar archivo
    docker cp deploy/dashboard.html "${CONTAINER_ID}:${DASHBOARD_PATH}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivo copiado correctamente"
        
        # Verificar que se copió
        if docker exec "$CONTAINER_ID" grep -q "Cargando hoteles para selector (knowledge/policies)" "$DASHBOARD_PATH" 2>/dev/null; then
            echo "✅ Verificación: Archivo actualizado correctamente"
        else
            echo "❌ Error: El archivo no se actualizó correctamente"
            exit 1
        fi
        
        # Reiniciar contenedor
        echo ""
        echo "7️⃣ Reiniciando contenedor..."
        docker restart "$CONTAINER_ID"
        sleep 5
        
        if docker ps | grep -q "$CONTAINER_ID"; then
            echo "✅ Contenedor reiniciado y corriendo"
        else
            echo "⚠️ El contenedor no está corriendo"
        fi
    else
        echo "❌ Error al copiar archivo"
        exit 1
    fi
else
    echo ""
    echo "✅ No se necesita actualizar, el contenedor ya tiene la versión correcta"
fi

echo ""
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Limpia la caché del navegador (Ctrl+Shift+R o Ctrl+F5)"
echo "   2. Recarga la página del dashboard"
echo "   3. Ve a Flor IA → Pestaña '📚 Conocimiento'"
echo "   4. Selecciona un hotel del selector"
echo "   5. Deberías ver toda la información del hotel"
echo ""
echo "🔍 Para verificar en la consola del navegador (F12):"
echo "   - Deberías ver: '🔄 Cargando hoteles para selector...'"
echo "   - Deberías ver: '🏨 Cargando hoteles para selector de Flor...'"
echo "   - Deberías ver: '✅ X hoteles cargados desde Supabase para selector'"
echo "   - Al seleccionar hotel: '🔍 loadSelectedHotelKnowledge ejecutándose...'"
echo "=========================================="

