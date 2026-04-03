#!/bin/bash
# Verificar versión del dashboard y estado de Traefik

echo "=========================================="
echo "🔍 Verificación de Versión y Traefik"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando versión del dashboard en el contenedor..."
FIRST_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$FIRST_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $FIRST_CONTAINER"
echo ""

# Verificar versión en dashboard.html
echo "--- Verificando dashboard.html ---"
DASHBOARD_VERSION=$(docker exec "$FIRST_CONTAINER" grep -oP "window\.DASHBOARD_VERSION = ['\"][^'\"]+['\"]" /app/dashboard.html 2>/dev/null | grep -oP "['\"][^'\"]+['\"]" | tr -d "'\"")
BUILD_TIMESTAMP=$(docker exec "$FIRST_CONTAINER" grep -oP "window\.BUILD_TIMESTAMP = ['\"][^'\"]+['\"]" /app/dashboard.html 2>/dev/null | grep -oP "['\"][^'\"]+['\"]" | tr -d "'\"")

if [ ! -z "$DASHBOARD_VERSION" ]; then
    echo "✅ Versión encontrada: $DASHBOARD_VERSION"
else
    echo "⚠️ No se encontró DASHBOARD_VERSION"
fi

if [ ! -z "$BUILD_TIMESTAMP" ]; then
    echo "✅ Build timestamp: $BUILD_TIMESTAMP"
else
    echo "⚠️ No se encontró BUILD_TIMESTAMP"
fi

# Verificar versión de supabase-client.js
echo ""
echo "--- Verificando supabase-client.js ---"
SUPABASE_VERSION=$(docker exec "$FIRST_CONTAINER" grep -oP "supabase-client\.js\?v=[0-9.]+" /app/dashboard.html 2>/dev/null | head -1)
if [ ! -z "$SUPABASE_VERSION" ]; then
    echo "✅ $SUPABASE_VERSION"
else
    echo "⚠️ No se encontró versión de supabase-client.js"
fi

# Verificar log de verificación temprana
echo ""
echo "--- Verificando log de verificación temprana ---"
HAS_VERIFICATION_LOG=$(docker exec "$FIRST_CONTAINER" grep -c "VERIFICACIÓN TEMPRANA DE VERSIÓN DEL CÓDIGO" /app/dashboard.html 2>/dev/null)
if [ "$HAS_VERIFICATION_LOG" -gt 0 ]; then
    echo "✅ Log de verificación temprana encontrado (código nuevo)"
else
    echo "❌ Log de verificación temprana NO encontrado (código viejo)"
fi

# Verificar fecha de modificación del archivo
echo ""
echo "--- Fecha de modificación del archivo ---"
FILE_DATE=$(docker exec "$FIRST_CONTAINER" stat -c %y /app/dashboard.html 2>/dev/null | cut -d' ' -f1)
if [ ! -z "$FILE_DATE" ]; then
    echo "Fecha: $FILE_DATE"
fi

echo ""
echo "2️⃣ Verificando estado de Traefik..."
echo ""

# Verificar etiquetas
SERVICE_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)
TRAEFIK_LABELS=$(echo "$SERVICE_LABELS" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ El servicio NO tiene etiquetas Traefik"
    echo ""
    echo "🔍 CAUSA: EasyPanel está sobrescribiendo las etiquetas"
    echo ""
    echo "✅ SOLUCIÓN: Configurar el dominio desde EasyPanel"
    echo ""
    echo "📋 PASOS EN EASYPANEL:"
    echo ""
    echo "   1. Ve a: http://72.61.58.240:3000"
    echo "   2. Proyecto: checkin24hs"
    echo "   3. Servicio: dashboard"
    echo "   4. Pestaña: '🔗 Dominios' o 'Domains'"
    echo "   5. Clic en: 'Agregar Dominio' o 'Add Domain'"
    echo "   6. Ingresa: dashboard.checkin24hs.com"
    echo "   7. Configura:"
    echo "      - HTTPS: ✅ Activado"
    echo "      - Puerto destino: 3000"
    echo "      - Ruta destino: /"
    echo "   8. Guarda"
    echo "   9. Espera 1-2 minutos"
    echo ""
else
    echo "✅ Etiquetas Traefik encontradas:"
    echo "$TRAEFIK_LABELS"
fi

echo ""
echo "3️⃣ Verificando si el servidor responde directamente..."
docker exec "$FIRST_CONTAINER" node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', {family: 4}, (res) => {
    console.log('Status:', res.statusCode);
    if (res.statusCode === 200) {
        console.log('✅ El servidor responde correctamente');
    }
    process.exit(res.statusCode === 200 ? 0 : 1);
}).on('error', (err) => {
    console.error('Error:', err.message);
    process.exit(1);
});
" 2>&1

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ "$HAS_VERIFICATION_LOG" -gt 0 ]; then
    echo "✅ Dashboard desplegado: Versión nueva"
else
    echo "❌ Dashboard desplegado: Versión VIEJA"
    echo ""
    echo "Solución:"
    echo "  1. Ve a EasyPanel → Servicio dashboard"
    echo "  2. Haz clic en 'Deploy' o 'Redeploy'"
    echo "  3. Espera 2-5 minutos"
    echo "  4. Haz Ctrl+Shift+R en el navegador para limpiar caché"
fi

echo ""
if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ Traefik: NO configurado"
    echo "   → Configura el dominio desde EasyPanel (pasos arriba)"
else
    echo "✅ Traefik: Configurado"
    echo "   → Espera 1-2 minutos y prueba: https://dashboard.checkin24hs.com"
fi

echo ""
