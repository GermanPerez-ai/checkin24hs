#!/bin/bash
# Restaurar botones rápidamente

echo "=== RESTAURANDO BOTONES ==="
echo ""

# Esperar a que el contenedor esté listo
sleep 5

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor, esperando 10 segundos más..."
    sleep 10
    CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
fi

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# Copiar archivo
echo "📤 Copiando dashboard.html..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Copiado"
    
    # Verificar
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "✅ Contiene botones" || \
        echo "❌ NO contiene botones"
    
    # Reiniciar proceso Node.js
    echo ""
    echo "🔄 Reiniciando proceso Node.js..."
    docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || true
    sleep 10
    
    echo "✅ Proceso reiniciado"
    echo ""
    echo "🌍 Verificando contenido servido..."
    sleep 5
    curl -s https://dashboard.checkin24hs.com 2>&1 | grep -q "whatsapp-config-button-main" && \
        echo "✅ Servidor sirviendo versión con botones" || \
        echo "⚠️  Puede tardar unos segundos en actualizarse"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi

echo ""
echo "=== COMPLETADO ==="





