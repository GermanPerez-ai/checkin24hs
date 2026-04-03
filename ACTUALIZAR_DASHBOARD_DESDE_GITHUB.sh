#!/bin/bash
# Script para actualizar dashboard.html en el servidor descargando desde GitHub

echo "=========================================="
echo "🔄 ACTUALIZANDO DASHBOARD DESDE GITHUB"
echo "=========================================="
echo ""

# 1. Buscar contenedor
echo "1️⃣ Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    exit 1
fi

CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep dashboard | grep -v proxy | head -1)
echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 2. Buscar ruta de dashboard.html en el contenedor
echo "2️⃣ Buscando dashboard.html en el contenedor..."
DASHBOARD_PATH=$(docker exec "$CONTAINER_ID" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    # Intentar rutas comunes
    for path in "/app/dashboard.html" "/usr/share/nginx/html/dashboard.html" "/var/www/html/dashboard.html"; do
        if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
            DASHBOARD_PATH="$path"
            break
        fi
    done
fi

if [ -z "$DASHBOARD_PATH" ]; then
    echo "⚠️  No se encontró dashboard.html, usando /app/dashboard.html por defecto"
    DASHBOARD_PATH="/app/dashboard.html"
else
    echo "✅ Encontrado en: $DASHBOARD_PATH"
fi
echo ""

# 3. Crear backup
echo "3️⃣ Creando backup del archivo actual..."
BACKUP_PATH="${DASHBOARD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "$BACKUP_PATH" 2>/dev/null || echo "⚠️  No se pudo crear backup (continuando de todas formas)"
echo "✅ Backup creado: $BACKUP_PATH"
echo ""

# 4. Descargar archivo desde GitHub
echo "4️⃣ Descargando dashboard.html desde GitHub..."
curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html -o /tmp/dashboard_new.html

if [ ! -f /tmp/dashboard_new.html ] || [ ! -s /tmp/dashboard_new.html ]; then
    echo "❌ Error al descargar desde GitHub"
    exit 1
fi

FILE_SIZE=$(wc -c < /tmp/dashboard_new.html)
echo "✅ Archivo descargado: $FILE_SIZE bytes ($(echo "scale=2; $FILE_SIZE/1024/1024" | bc) MB)"
echo ""

# 5. Verificar versión en el archivo descargado
echo "5️⃣ Verificando versión en el archivo descargado..."
SUPABASE_VERSION=$(grep -oE 'supabase-client\.js\?v=[0-9.]+' /tmp/dashboard_new.html | head -1 | grep -oE '[0-9.]+' || echo "")
if [ -n "$SUPABASE_VERSION" ]; then
    echo "   Versión de supabase-client.js: v$SUPABASE_VERSION"
    if [ "$SUPABASE_VERSION" = "3.1.1" ]; then
        echo "   ✅ Versión CORRECTA (v3.1.1)"
    else
        echo "   ⚠️  Versión diferente (esperada: v3.1.1)"
    fi
else
    echo "   ⚠️  No se encontró versión"
fi

DASHBOARD_VERSION=$(grep -oE "DASHBOARD_VERSION = '[0-9.]+'" /tmp/dashboard_new.html | head -1 | grep -oE '[0-9.]+' || echo "")
if [ -n "$DASHBOARD_VERSION" ]; then
    echo "   Versión del dashboard: $DASHBOARD_VERSION"
    if [ "$DASHBOARD_VERSION" = "2.1.0" ]; then
        echo "   ✅ Versión CORRECTA (2.1.0)"
    else
        echo "   ⚠️  Versión diferente (esperada: 2.1.0)"
    fi
fi
echo ""

# 6. Copiar archivo al contenedor
echo "6️⃣ Copiando archivo al contenedor..."
docker cp /tmp/dashboard_new.html "$CONTAINER_ID:$DASHBOARD_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi
echo ""

# 7. Verificar que se copió correctamente
echo "7️⃣ Verificando que se copió correctamente..."
VERIFY_SIZE=$(docker exec "$CONTAINER_ID" stat -c%s "$DASHBOARD_PATH" 2>/dev/null || docker exec "$CONTAINER_ID" stat -f%z "$DASHBOARD_PATH" 2>/dev/null || echo "0")
echo "   Tamaño en contenedor: $VERIFY_SIZE bytes"

if [ "$VERIFY_SIZE" -gt "1000000" ]; then
    echo "✅ Archivo verificado (tamaño correcto)"
else
    echo "⚠️  Tamaño sospechoso (esperado >1MB)"
fi
echo ""

# 8. Verificar versión en el contenedor
echo "8️⃣ Verificando versión en el contenedor..."
CONTAINER_SUPABASE_VERSION=$(docker exec "$CONTAINER_ID" grep -oE 'supabase-client\.js\?v=[0-9.]+' "$DASHBOARD_PATH" 2>/dev/null | head -1 | grep -oE '[0-9.]+' || echo "")
if [ -n "$CONTAINER_SUPABASE_VERSION" ]; then
    echo "   Versión de supabase-client.js: v$CONTAINER_SUPABASE_VERSION"
    if [ "$CONTAINER_SUPABASE_VERSION" = "3.1.1" ]; then
        echo "   ✅ Versión CORRECTA en el contenedor (v3.1.1)"
    else
        echo "   ⚠️  Versión INCORRECTA en el contenedor (actual: v$CONTAINER_SUPABASE_VERSION, esperada: v3.1.1)"
    fi
fi
echo ""

# 9. Reiniciar contenedor (si es necesario)
echo "9️⃣ ¿Reiniciar contenedor? (opcional)"
read -p "   Presiona Enter para continuar sin reiniciar, o escribe 'si' para reiniciar: " REINICIAR

if [ "$REINICIAR" = "si" ] || [ "$REINICIAR" = "SI" ] || [ "$REINICIAR" = "s" ] || [ "$REINICIAR" = "S" ]; then
    echo "   🔄 Reiniciando contenedor..."
    docker restart "$CONTAINER_ID"
    echo "   ✅ Contenedor reiniciado"
    echo "   ⏳ Esperando 10 segundos..."
    sleep 10
else
    echo "   ℹ️  Contenedor no reiniciado (puedes reiniciarlo manualmente si es necesario)"
fi
echo ""

# 10. Resumen
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo "✅ Archivo actualizado desde GitHub"
echo "✅ Backup creado: $BACKUP_PATH"
if [ "$CONTAINER_SUPABASE_VERSION" = "3.1.1" ]; then
    echo "✅ Versión CORRECTA instalada (v3.1.1)"
    echo ""
    echo "💡 Próximos pasos:"
    echo "   1. Recarga la página con Ctrl+Shift+R"
    echo "   2. Verifica la consola del navegador"
    echo "   3. Deberías ver: supabase-client.js?v=3.1.1"
else
    echo "⚠️  Verifica manualmente la versión en el contenedor"
fi
echo ""
echo "=========================================="
