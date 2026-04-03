#!/bin/bash
# Script completo para verificar y actualizar el dashboard si es necesario

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICACIÓN Y ACTUALIZACIÓN DEL DASHBOARD"
echo "=========================================="
echo ""

# Buscar contenedor del dashboard
echo "1️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "📋 Contenedores corriendo:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -i dashboard || echo "   Ninguno encontrado"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep dashboard | grep -v nginx | head -1)
echo "   Nombre: $CONTAINER_NAME"
echo ""

# Buscar ruta del dashboard en el contenedor
echo "2️⃣ Buscando archivo dashboard.html en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
    "/app/deploy/dashboard.html"
    "/app/index.html"
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
    echo "⚠️ No se encontró dashboard.html, listando archivos en /app:"
    docker exec "$CONTAINER_ID" ls -la /app 2>/dev/null | head -20
    exit 1
fi

echo ""

# Verificar versión en el contenedor
echo "3️⃣ Verificando versión en el contenedor..."
HAS_FUNCTION=false
HAS_CALL=false
HAS_FILTER=false

if docker exec "$CONTAINER_ID" grep -q "async function loadHotelsForFlor" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Función loadHotelsForFlor encontrada"
    HAS_FUNCTION=true
else
    echo "❌ Función loadHotelsForFlor NO encontrada"
fi

if docker exec "$CONTAINER_ID" grep -q "loadHotelsForFlor().catch" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Llamada con .catch() encontrada"
    HAS_CALL=true
else
    echo "❌ Llamada con .catch() NO encontrada"
fi

if docker exec "$CONTAINER_ID" grep -q "hotel.active !== false && hotel.activo !== false" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Filtro de hoteles activos encontrado"
    HAS_FILTER=true
else
    echo "❌ Filtro de hoteles activos NO encontrado"
fi

CONTAINER_VERSION_OK=$([ "$HAS_FUNCTION" = true ] && [ "$HAS_CALL" = true ] && [ "$HAS_FILTER" = true ] && echo "true" || echo "false")

echo ""

# Verificar qué se está sirviendo realmente
echo "4️⃣ Verificando qué se está sirviendo en https://dashboard.checkin24hs.com..."
SERVED_CONTENT=$(curl -s -k https://dashboard.checkin24hs.com 2>/dev/null | head -100)

if [ -z "$SERVED_CONTENT" ]; then
    echo "⚠️ No se pudo obtener contenido del servidor"
    echo "   Intentando con http..."
    SERVED_CONTENT=$(curl -s http://dashboard.checkin24hs.com 2>/dev/null | head -100)
fi

if [ -n "$SERVED_CONTENT" ]; then
    SERVED_HAS_FUNCTION=false
    SERVED_HAS_CALL=false
    SERVED_HAS_FILTER=false
    
    echo "$SERVED_CONTENT" | grep -q "async function loadHotelsForFlor" && SERVED_HAS_FUNCTION=true
    echo "$SERVED_CONTENT" | grep -q "loadHotelsForFlor().catch" && SERVED_HAS_CALL=true
    echo "$SERVED_CONTENT" | grep -q "hotel.active !== false && hotel.activo !== false" && SERVED_HAS_FILTER=true
    
    echo "   Función loadHotelsForFlor: $([ "$SERVED_HAS_FUNCTION" = true ] && echo "✅" || echo "❌")"
    echo "   Llamada con .catch(): $([ "$SERVED_HAS_CALL" = true ] && echo "✅" || echo "❌")"
    echo "   Filtro hoteles activos: $([ "$SERVED_HAS_FILTER" = true ] && echo "✅" || echo "❌")"
    
    SERVED_VERSION_OK=$([ "$SERVED_HAS_FUNCTION" = true ] && [ "$SERVED_HAS_CALL" = true ] && [ "$SERVED_HAS_FILTER" = true ] && echo "true" || echo "false")
else
    echo "❌ No se pudo verificar el contenido servido"
    SERVED_VERSION_OK="unknown"
fi

echo ""

# Verificar archivo local
echo "5️⃣ Verificando archivo local..."
LOCAL_FILE=""
if [ -f "deploy/dashboard.html" ]; then
    LOCAL_FILE="deploy/dashboard.html"
elif [ -f "dashboard.html" ]; then
    LOCAL_FILE="dashboard.html"
fi

if [ -n "$LOCAL_FILE" ]; then
    echo "✅ Archivo local encontrado: $LOCAL_FILE"
    LOCAL_SIZE=$(stat -c%s "$LOCAL_FILE" 2>/dev/null || stat -f%z "$LOCAL_FILE" 2>/dev/null)
    echo "   Tamaño: $LOCAL_SIZE bytes"
    
    LOCAL_HAS_FUNCTION=false
    LOCAL_HAS_CALL=false
    LOCAL_HAS_FILTER=false
    
    grep -q "async function loadHotelsForFlor" "$LOCAL_FILE" 2>/dev/null && LOCAL_HAS_FUNCTION=true
    grep -q "loadHotelsForFlor().catch" "$LOCAL_FILE" 2>/dev/null && LOCAL_HAS_CALL=true
    grep -q "hotel.active !== false && hotel.activo !== false" "$LOCAL_FILE" 2>/dev/null && LOCAL_HAS_FILTER=true
    
    echo "   Función loadHotelsForFlor: $([ "$LOCAL_HAS_FUNCTION" = true ] && echo "✅" || echo "❌")"
    echo "   Llamada con .catch(): $([ "$LOCAL_HAS_CALL" = true ] && echo "✅" || echo "❌")"
    echo "   Filtro hoteles activos: $([ "$LOCAL_HAS_FILTER" = true ] && echo "✅" || echo "❌")"
    
    LOCAL_VERSION_OK=$([ "$LOCAL_HAS_FUNCTION" = true ] && [ "$LOCAL_HAS_CALL" = true ] && [ "$LOCAL_HAS_FILTER" = true ] && echo "true" || echo "false")
else
    echo "⚠️ No se encontró archivo local (deploy/dashboard.html o dashboard.html)"
    LOCAL_VERSION_OK="unknown"
fi

echo ""

# Resumen y decisión
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Contenedor: $CONTAINER_ID"
echo "Ruta en contenedor: $DASHBOARD_PATH"
echo ""
echo "Versión en contenedor: $([ "$CONTAINER_VERSION_OK" = true ] && echo "✅ NUEVA" || echo "❌ ANTIGUA")"
echo "Versión servida: $([ "$SERVED_VERSION_OK" = true ] && echo "✅ NUEVA" || [ "$SERVED_VERSION_OK" = "unknown" ] && echo "⚠️ DESCONOCIDA" || echo "❌ ANTIGUA")"
echo "Versión local: $([ "$LOCAL_VERSION_OK" = true ] && echo "✅ NUEVA" || [ "$LOCAL_VERSION_OK" = "unknown" ] && echo "⚠️ NO DISPONIBLE" || echo "❌ ANTIGUA")"
echo ""

# Decidir si actualizar
NEEDS_UPDATE=false

if [ "$CONTAINER_VERSION_OK" != "true" ]; then
    echo "⚠️ El archivo en el contenedor es ANTIGUO"
    NEEDS_UPDATE=true
fi

if [ "$SERVED_VERSION_OK" != "true" ] && [ "$SERVED_VERSION_OK" != "unknown" ]; then
    echo "⚠️ El contenido servido es ANTIGUO"
    NEEDS_UPDATE=true
fi

if [ "$NEEDS_UPDATE" = true ] && [ "$LOCAL_VERSION_OK" = "true" ]; then
    echo ""
    echo "=========================================="
    echo "🔄 ACTUALIZANDO DASHBOARD"
    echo "=========================================="
    echo ""
    
    # Hacer backup
    echo "1️⃣ Haciendo backup..."
    BACKUP_PATH="${DASHBOARD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "$BACKUP_PATH" 2>/dev/null && echo "✅ Backup creado" || echo "⚠️ No se pudo crear backup"
    
    # Copiar archivo
    echo ""
    echo "2️⃣ Copiando archivo al contenedor..."
    docker cp "$LOCAL_FILE" "${CONTAINER_ID}:${DASHBOARD_PATH}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivo copiado"
        
        # Verificar que se copió correctamente
        echo ""
        echo "3️⃣ Verificando archivo copiado..."
        if docker exec "$CONTAINER_ID" grep -q "async function loadHotelsForFlor" "$DASHBOARD_PATH" 2>/dev/null; then
            echo "✅ Archivo actualizado correctamente"
            
            # Reiniciar contenedor
            echo ""
            echo "4️⃣ Reiniciando contenedor..."
            docker restart "$CONTAINER_ID"
            
            if [ $? -eq 0 ]; then
                echo "✅ Contenedor reiniciado"
                echo ""
                echo "⏳ Esperando 5 segundos para que el contenedor inicie..."
                sleep 5
                
                # Verificar que está corriendo
                if docker ps | grep -q "$CONTAINER_ID"; then
                    echo "✅ Contenedor está corriendo"
                else
                    echo "⚠️ El contenedor no está corriendo, verifica los logs:"
                    echo "   docker logs $CONTAINER_ID"
                fi
            else
                echo "❌ Error al reiniciar contenedor"
            fi
        else
            echo "❌ El archivo no se copió correctamente"
        fi
    else
        echo "❌ Error al copiar archivo"
    fi
elif [ "$NEEDS_UPDATE" = true ] && [ "$LOCAL_VERSION_OK" != "true" ]; then
    echo ""
    echo "⚠️ Se necesita actualización pero el archivo local también es antiguo"
    echo "   Por favor, sube una versión nueva de dashboard.html al servidor"
elif [ "$CONTAINER_VERSION_OK" = "true" ] && [ "$SERVED_VERSION_OK" != "true" ] && [ "$SERVED_VERSION_OK" != "unknown" ]; then
    echo ""
    echo "⚠️ El archivo en el contenedor es nuevo, pero el servido es antiguo"
    echo "   Esto puede ser un problema de caché. Intenta:"
    echo "   1. Limpiar caché del navegador (Ctrl+Shift+R)"
    echo "   2. Reiniciar el contenedor: docker restart $CONTAINER_ID"
    echo "   3. Verificar que no haya un proxy/CDN cacheando"
else
    echo ""
    echo "✅ TODO ESTÁ ACTUALIZADO"
fi

echo ""
echo "=========================================="
echo "📋 PRÓXIMOS PASOS"
echo "=========================================="
echo "1. Limpia la caché del navegador (Ctrl+Shift+R o Ctrl+F5)"
echo "2. Recarga la página del dashboard"
echo "3. Verifica que los hoteles se cargan en Flor IA"
echo ""
echo "🔍 Para verificar nuevamente:"
echo "   bash VERIFICAR_Y_ACTUALIZAR_DASHBOARD.sh"
echo "=========================================="
