#!/bin/bash
cd /root/checkin24hs

echo "=== APLICANDO DASHBOARD CON BOTONES DE CONFIGURACIÓN WHATSAPP ==="
echo ""

# Verificar que el archivo tiene los botones
echo "📋 Verificando que el archivo tiene los botones de configuración..."
if grep -q "whatsapp-config-button-main" /root/checkin24hs/deploy/dashboard.html; then
    echo "✅ Archivo tiene los botones de configuración WhatsApp"
else
    echo "❌ Archivo NO tiene los botones - necesita ser subido primero"
    echo "   Por favor, sube el archivo dashboard.html desde tu máquina local"
    exit 1
fi

echo ""
echo "🛑 Deteniendo contenedores de dashboard..."
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker stop
sleep 3

echo ""
echo "📦 Copiando dashboard.html a todos los contenedores..."
CONTADOR=0
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    if docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null; then
        echo "✅ Copiado a $c"
        CONTADOR=$((CONTADOR + 1))
    else
        echo "❌ Error al copiar a $c"
    fi
done

echo ""
echo "🚀 Iniciando contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker start
sleep 5

echo ""
echo "=== VERIFICACIÓN ==="
VERIFICADOS=0
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    fecha=$(docker exec $c ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    if docker exec $c grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null; then
        echo "✅ $c: $fecha (con botones de configuración)"
        VERIFICADOS=$((VERIFICADOS + 1))
    else
        echo "⚠️ $c: $fecha (SIN botones - necesita recopiar)"
    fi
done

echo ""
echo "✅ Completado"
echo ""
echo "📝 INSTRUCCIONES:"
echo "   1. Recarga el dashboard con Ctrl+Shift+R (recarga completa sin caché)"
echo "   2. Ve a Flor IA → WhatsApp"
echo "   3. Deberías ver el botón 'Configurar Servidor' en la parte superior"
echo ""






