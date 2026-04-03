#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICANDO Y APLICANDO FIX DE DETECCIÓN SSL ==="
echo ""

# Verificar que el archivo tiene los cambios
echo "📋 Verificando que el archivo tiene los cambios de detección SSL..."
if grep -q "🔍 lastWhatsAppError:" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo tiene los cambios de detección SSL (línea con 🔍 lastWhatsAppError:)"
else
    echo "❌ Archivo NO tiene los cambios - necesita ser subido primero"
    exit 1
fi

if grep -q "localStorage.setItem('lastWhatsAppError', 'ERR_CERT')" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo tiene el código que guarda ERR_CERT"
else
    echo "❌ Archivo NO tiene el código que guarda ERR_CERT"
    exit 1
fi

echo ""
echo "🛑 Deteniendo contenedores..."
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker stop
sleep 3

echo ""
echo "📦 Copiando archivo a contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html && echo "✅ $c" || echo "❌ $c"
done

echo ""
echo "🚀 Iniciando contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker start
sleep 5

echo ""
echo "=== VERIFICACIÓN FINAL ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    fecha=$(docker exec $c ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    if docker exec $c grep -q "🔍 lastWhatsAppError:" /app/dashboard.html 2>/dev/null; then
        echo "✅ $c: $fecha (CON cambios SSL)"
    else
        echo "⚠️ $c: $fecha (SIN cambios SSL - necesita recopiar)"
    fi
    
    if docker exec $c grep -q "localStorage.setItem('lastWhatsAppError', 'ERR_CERT')" /app/dashboard.html 2>/dev/null; then
        echo "   ✅ Código ERR_CERT presente"
    else
        echo "   ❌ Código ERR_CERT NO presente"
    fi
done

echo ""
echo "✅ Completado - Recarga el dashboard con Ctrl+Shift+R"
echo "📝 Después de recargar, intenta conectar WhatsApp y deberías ver:"
echo "   - 🔍 lastWhatsAppError: ERR_CERT"
echo "   - 🔍 serverUrl: https://api1.checkin24hs.com"
echo "   - 🔍 isSSLError: true"
echo "   - Un mensaje de alerta específico sobre certificado SSL"






