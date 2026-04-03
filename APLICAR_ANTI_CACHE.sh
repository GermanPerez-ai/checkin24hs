#!/bin/bash
cd /root/checkin24hs

echo "=== APLICANDO CONFIGURACIÓN ANTI-CACHÉ AL DASHBOARD ==="
echo ""

# Verificar que el archivo tiene los meta tags anti-caché
echo "📋 Verificando meta tags anti-caché en dashboard.html..."
if grep -q "Cache-Control.*no-cache" deploy/dashboard.html; then
    echo "✅ dashboard.html tiene meta tags anti-caché"
else
    echo "❌ dashboard.html NO tiene meta tags anti-caché - necesita ser actualizado"
    exit 1
fi

echo ""
echo "🛑 Deteniendo contenedores de dashboard..."
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker stop
sleep 3

echo ""
echo "📦 Copiando dashboard.html y nginx.conf a todos los contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    # Copiar dashboard.html
    docker cp /root/checkin24hs/deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null && echo "✅ dashboard.html copiado a $c" || echo "❌ Error copiando dashboard.html a $c"
    
    # Copiar nginx.conf si existe
    if [ -f /root/checkin24hs/deploy/nginx.conf ]; then
        docker cp /root/checkin24hs/deploy/nginx.conf $c:/etc/nginx/conf.d/default.conf 2>/dev/null && echo "✅ nginx.conf copiado a $c" || echo "⚠️ nginx.conf no se pudo copiar (puede ser normal si usa otro servidor web)"
    fi
done

echo ""
echo "🚀 Iniciando contenedores..."
docker ps -a --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | xargs -r docker start
sleep 5

echo ""
echo "=== VERIFICACIÓN ==="
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | while read c; do
    fecha=$(docker exec $c ls -lh /app/dashboard.html 2>/dev/null | awk '{print $6, $7, $8}')
    if docker exec $c grep -q "Cache-Control.*no-cache" /app/dashboard.html 2>/dev/null; then
        echo "✅ $c: $fecha (con anti-caché)"
    else
        echo "⚠️ $c: $fecha (SIN anti-caché - necesita recopiar)"
    fi
done

echo ""
echo "✅ Completado"
echo ""
echo "📝 INSTRUCCIONES PARA EL USUARIO:"
echo "   1. En tu teléfono, abre el dashboard: https://dashboard.checkin24hs.com/#"
echo "   2. Si aún ves la versión antigua:"
echo "      - Cierra completamente el navegador (no solo la pestaña)"
echo "      - Abre el navegador de nuevo"
echo "      - Ve a: https://dashboard.checkin24hs.com/#?v=$(date +%s)"
echo "      - O limpia el caché del navegador manualmente"
echo "   3. El sistema ahora detectará automáticamente nuevas versiones cada 5 minutos"
echo ""

