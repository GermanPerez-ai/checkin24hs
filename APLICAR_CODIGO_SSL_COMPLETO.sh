#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO Y APLICANDO CÓDIGO SSL COMPLETO ==="
echo ""

# PASO 1: Verificar que el archivo local tiene los cambios
echo "📋 PASO 1: Verificando archivo local..."
if grep -q "🔍 lastWhatsAppError:" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo local tiene los cambios de detección SSL"
else
    echo "❌ Archivo local NO tiene los cambios - necesita ser subido primero"
    echo "   Ejecuta desde tu máquina local:"
    echo "   scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

if grep -q "console.log('🔍 lastWhatsAppError:', lastError);" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo local tiene los logs de depuración"
else
    echo "❌ Archivo local NO tiene los logs de depuración"
    exit 1
fi

if grep -q "console.log('🔍 isSSLError:', isSSLError" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo local tiene el log de isSSLError"
else
    echo "❌ Archivo local NO tiene el log de isSSLError"
    exit 1
fi

# PASO 2: Verificar que el archivo en el servidor tiene los cambios
echo ""
echo "📋 PASO 2: Verificando archivo en servidor..."
if grep -q "🔍 lastWhatsAppError:" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo en servidor tiene los cambios"
else
    echo "⚠️ Archivo en servidor NO tiene los cambios - necesita ser subido"
    echo "   Ejecuta desde tu máquina local:"
    echo "   scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
    exit 1
fi

# PASO 3: Detener contenedores
echo ""
echo "🛑 PASO 3: Deteniendo contenedores..."
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker stop
sleep 3

# PASO 4: Copiar archivo a contenedores
echo ""
echo "📦 PASO 4: Copiando archivo a contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html && echo "✅ $c" || echo "❌ $c"
done

# PASO 5: Iniciar contenedores
echo ""
echo "🚀 PASO 5: Iniciando contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker start
sleep 5

# PASO 6: Verificar que los cambios están en los contenedores
echo ""
echo "=== VERIFICACIÓN FINAL ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    fecha=$(docker exec $c ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    
    # Verificar cada cambio específico
    hasDebugLog=$(docker exec $c grep -q "🔍 lastWhatsAppError:" /app/dashboard.html 2>/dev/null && echo "SÍ" || echo "NO")
    hasSSLLog=$(docker exec $c grep -q "🔍 isSSLError:" /app/dashboard.html 2>/dev/null && echo "SÍ" || echo "NO")
    hasERRCERT=$(docker exec $c grep -q "localStorage.setItem('lastWhatsAppError', 'ERR_CERT')" /app/dashboard.html 2>/dev/null && echo "SÍ" || echo "NO")
    
    if [ "$hasDebugLog" = "SÍ" ] && [ "$hasSSLLog" = "SÍ" ] && [ "$hasERRCERT" = "SÍ" ]; then
        echo "✅ $c: $fecha (CON todos los cambios SSL)"
    else
        echo "⚠️ $c: $fecha"
        echo "   - Logs de depuración: $hasDebugLog"
        echo "   - Log SSL: $hasSSLLog"
        echo "   - Código ERR_CERT: $hasERRCERT"
    fi
done

echo ""
echo "✅ Completado"
echo ""
echo "📝 INSTRUCCIONES:"
echo "1. Recarga el dashboard con Ctrl+Shift+R (recarga completa sin caché)"
echo "2. Abre la consola del navegador (F12)"
echo "3. Intenta conectar WhatsApp"
echo "4. Deberías ver en la consola:"
echo "   - 🔍 lastWhatsAppError: ERR_CERT"
echo "   - 🔍 serverUrl: https://api1.checkin24hs.com"
echo "   - 🔍 isSSLError: true"
echo "   - Un mensaje de alerta específico sobre certificado SSL"






