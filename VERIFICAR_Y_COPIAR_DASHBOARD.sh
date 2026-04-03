#!/bin/bash
# Verificar y copiar dashboard.html correctamente

echo "=== VERIFICACIÓN Y COPIA DE DASHBOARD ==="
echo ""

# 1. Verificar archivo local
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Error: No se encuentra deploy/dashboard.html"
    echo "   Por favor, sube el archivo primero:"
    echo "   scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
echo "✅ Archivo local encontrado: $LOCAL_SIZE bytes"
echo ""

# Verificar que tiene los botones
echo "🔍 Verificando contenido local..."
grep -q "whatsapp-config-button-main" deploy/dashboard.html && \
    echo "   ✅ Contiene botones de WhatsApp" || \
    echo "   ❌ NO contiene botones de WhatsApp"
grep -q "Configurar Servidor" deploy/dashboard.html && \
    echo "   ✅ Contiene texto 'Configurar Servidor'" || \
    echo "   ❌ NO contiene texto 'Configurar Servidor'"
echo ""

# 2. Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 3. Buscar dashboard.html en el contenedor
echo "🔍 Buscando dashboard.html en el contenedor..."
DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$DASHBOARD_PATH" ]; then
    echo "   Buscando en rutas comunes..."
    for path in "/app/dashboard.html" "/usr/src/app/dashboard.html" "/root/checkin24hs/dashboard.html" "/dashboard.html"; do
        if docker exec "$CONTAINER" test -f "$path" 2>/dev/null; then
            DASHBOARD_PATH="$path"
            echo "   ✅ Encontrado en: $DASHBOARD_PATH"
            break
        fi
    done
fi

if [ -z "$DASHBOARD_PATH" ]; then
    echo "   ⚠️  No se encontró, listando estructura:"
    docker exec "$CONTAINER" ls -la / 2>/dev/null | head -20
    echo ""
    echo "   Por favor, indica la ruta:"
    read -r DASHBOARD_PATH
else
    echo "   ✅ Encontrado en: $DASHBOARD_PATH"
fi

echo ""

# 4. Verificar contenido actual en el contenedor
echo "📊 Verificando contenido actual en contenedor:"
CONTAINER_SIZE=$(docker exec "$CONTAINER" stat -c%s "$DASHBOARD_PATH" 2>/dev/null || docker exec "$CONTAINER" stat -f%z "$DASHBOARD_PATH" 2>/dev/null || echo "0")
echo "   Tamaño actual: $CONTAINER_SIZE bytes"
echo "   Tamaño nuevo: $LOCAL_SIZE bytes"

docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" "$DASHBOARD_PATH" 2>/dev/null && \
    echo "   ✅ Contiene botones de WhatsApp" || \
    echo "   ❌ NO contiene botones de WhatsApp (necesita actualización)"

echo ""

# 5. Copiar archivo
echo "📤 Copiando dashboard.html..."
docker cp deploy/dashboard.html "${CONTAINER}:${DASHBOARD_PATH}"

if [ $? -ne 0 ]; then
    echo "   ❌ Error al copiar"
    exit 1
fi

echo "   ✅ Archivo copiado"
echo ""

# 6. Verificar después de copiar
echo "🔍 Verificando después de copiar..."
NEW_SIZE=$(docker exec "$CONTAINER" stat -c%s "$DASHBOARD_PATH" 2>/dev/null || docker exec "$CONTAINER" stat -f%z "$DASHBOARD_PATH" 2>/dev/null || echo "0")
echo "   Tamaño después de copiar: $NEW_SIZE bytes"

if [ "$NEW_SIZE" != "$LOCAL_SIZE" ]; then
    echo "   ⚠️  ADVERTENCIA: Los tamaños no coinciden!"
    echo "   Local: $LOCAL_SIZE bytes"
    echo "   Contenedor: $NEW_SIZE bytes"
else
    echo "   ✅ Tamaño verificado correctamente"
fi

docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" "$DASHBOARD_PATH" 2>/dev/null && \
    echo "   ✅ Contiene botones de WhatsApp" || \
    echo "   ❌ NO contiene botones de WhatsApp"

echo ""

# 7. Reiniciar servicio
echo "🔄 Reiniciando servicio..."
docker service update --force checkin24hs_dashboard 2>&1 | grep -v "update paused\|update in progress" || true

echo ""
echo "⏳ Esperando 25 segundos para que el servicio se reinicie..."
sleep 25

# 8. Verificar contenido servido
echo ""
echo "🌍 Verificando contenido servido por HTTPS:"
curl -s https://dashboard.checkin24hs.com 2>&1 | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ El servidor está sirviendo la versión con botones" || \
    echo "   ❌ El servidor NO está sirviendo la versión con botones"

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📋 Prueba ahora:"
echo "   1. Abre https://dashboard.checkin24hs.com en modo incógnito"
echo "   2. Presiona Ctrl+Shift+R para forzar recarga"
echo "   3. Ve a la sección de WhatsApp"
echo "   4. Deberías ver los botones 'Configurar Servidor'"
echo ""





