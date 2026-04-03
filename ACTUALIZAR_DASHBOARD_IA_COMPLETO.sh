#!/bin/bash
# Script completo para actualizar dashboard.html con configuración de IA completa

cd /root/checkin24hs

echo "=========================================="
echo "🔄 ACTUALIZANDO DASHBOARD CON IA COMPLETA"
echo "=========================================="
echo ""

# 1. Verificar que el archivo existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ No se encontró deploy/dashboard.html"
    echo "📥 Descargando desde GitHub..."
    
    # Intentar descargar desde GitHub si existe
    if command -v git &> /dev/null; then
        if [ -d ".git" ]; then
            git pull origin main
        fi
    fi
    
    if [ ! -f "deploy/dashboard.html" ]; then
        echo "❌ Error: No se puede encontrar dashboard.html"
        exit 1
    fi
fi

echo "✅ Archivo encontrado: deploy/dashboard.html"
LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "   Tamaño: $LOCAL_SIZE bytes"
echo ""

# 2. Verificar que tiene los campos de IA
echo "2️⃣ Verificando campos de IA en el archivo..."
if grep -q "ai-temperature" deploy/dashboard.html && grep -q "ai-max-tokens" deploy/dashboard.html; then
    echo "✅ Campos de Temperature y Max Tokens encontrados"
else
    echo "❌ ERROR: Los campos de IA NO están en el archivo"
    echo "   El archivo necesita ser actualizado desde el repositorio"
    exit 1
fi

# 3. Buscar contenedor del dashboard
echo ""
echo "3️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "📋 Contenedores corriendo:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep dashboard | grep -v nginx | head -1)
echo "   Nombre: $CONTAINER_NAME"
echo ""

# 4. Buscar ruta del dashboard en el contenedor
echo "4️⃣ Buscando ruta del dashboard en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
    "/app/deploy/dashboard.html"
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
    echo "⚠️ No se encontró dashboard.html, usando /app/dashboard.html"
    DASHBOARD_PATH="/app/dashboard.html"
fi

# 5. Hacer backup
echo ""
echo "5️⃣ Haciendo backup del archivo actual..."
BACKUP_PATH="${DASHBOARD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
if docker exec "$CONTAINER_ID" test -f "$DASHBOARD_PATH" 2>/dev/null; then
    docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "$BACKUP_PATH" 2>/dev/null
    echo "✅ Backup creado: $BACKUP_PATH"
else
    echo "⚠️ No existe archivo previo"
fi

# 6. Copiar archivo al contenedor
echo ""
echo "6️⃣ Copiando archivo actualizado al contenedor..."
docker cp deploy/dashboard.html "${CONTAINER_ID}:${DASHBOARD_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi

# 7. Verificar que se copió correctamente
echo ""
echo "7️⃣ Verificando archivo copiado..."
REMOTE_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s "$DASHBOARD_PATH" 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z "$DASHBOARD_PATH" 2>/dev/null)

if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ]; then
    echo "✅ Tamaños coinciden ($REMOTE_SIZE bytes)"
else
    echo "⚠️ Tamaños NO coinciden (local: $LOCAL_SIZE, remoto: $REMOTE_SIZE)"
fi

# Verificar campos de IA
if docker exec "$CONTAINER_ID" grep -q "ai-temperature" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Campo ai-temperature encontrado en contenedor"
else
    echo "❌ Campo ai-temperature NO encontrado en contenedor"
fi

if docker exec "$CONTAINER_ID" grep -q "ai-max-tokens" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Campo ai-max-tokens encontrado en contenedor"
else
    echo "❌ Campo ai-max-tokens NO encontrado en contenedor"
fi

# 8. Reiniciar contenedor
echo ""
echo "8️⃣ Reiniciando contenedor..."
docker restart "$CONTAINER_ID"

if [ $? -eq 0 ]; then
    echo "✅ Contenedor reiniciado"
    echo ""
    echo "⏳ Esperando 10 segundos para que el contenedor inicie completamente..."
    sleep 10
    
    # Verificar que está corriendo
    if docker ps | grep -q "$CONTAINER_ID"; then
        echo "✅ Contenedor está corriendo"
    else
        echo "⚠️ El contenedor no está corriendo, verifica los logs:"
        echo "   docker logs $CONTAINER_ID"
    fi
else
    echo "❌ Error al reiniciar contenedor"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 IMPORTANTE - Próximos pasos:"
echo ""
echo "1. 🔄 LIMPIA LA CACHÉ DEL NAVEGADOR:"
echo "   - Presiona Ctrl+Shift+R (o Ctrl+F5)"
echo "   - O abre en modo incógnito/privado"
echo ""
echo "2. 📍 Ve a: Flor IA → Pestaña '🤖 IA'"
echo ""
echo "3. ✅ Deberías ver ahora:"
echo "   - Checkbox 'Habilitar respuestas con IA'"
echo "   - Selector 'Proveedor'"
echo "   - Campo 'API Key'"
echo "   - Campo 'Modelo'"
echo "   - Campo 'Temperature' (NUEVO)"
echo "   - Campo 'Max Tokens' (NUEVO)"
echo "   - Botón 'Guardar'"
echo "   - Botón 'Probar Conexión'"
echo ""
echo "4. 🔍 Si aún no aparecen los campos:"
echo "   - Marca y desmarca el checkbox 'Habilitar respuestas con IA'"
echo "   - Verifica la consola del navegador (F12) por errores"
echo ""
echo "=========================================="








