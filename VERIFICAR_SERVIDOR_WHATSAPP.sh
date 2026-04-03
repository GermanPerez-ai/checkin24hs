#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO SERVIDOR DE WHATSAPP"
echo "=========================================="
echo ""

# Verificar contenedores de WhatsApp
echo "📋 Contenedores de WhatsApp activos:"
echo "=========================================="
docker ps --filter "name=whatsapp" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Verificar si el servidor está respondiendo
echo "🌐 Verificando respuesta del servidor:"
echo "=========================================="
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo ""
    echo "📊 Estado del contenedor:"
    docker inspect "$CONTAINER" --format "Estado: {{.State.Status}}"
    echo ""
    echo "🔌 Puertos expuestos:"
    docker port "$CONTAINER" 2>/dev/null || echo "No hay puertos expuestos"
    echo ""
    echo "📝 Últimos logs (últimas 30 líneas):"
    docker logs "$CONTAINER" --tail 30 2>&1 | tail -30
    echo ""
    echo "❌ Errores recientes:"
    docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "error\|failed\|exception\|502\|bad gateway" | tail -10
    echo ""
    echo "✅ Mensajes de conexión exitosa:"
    docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "connected\|ready\|qr\|scan" | tail -10
else
    echo "❌ No se encontró contenedor de WhatsApp 1"
fi

echo ""
echo "=========================================="
echo "📋 VERIFICAR MANUALMENTE:"
echo "=========================================="
echo ""
echo "1. Verifica que el servidor esté corriendo:"
echo "   curl -I https://api1.checkin24hs.com/api/status?card=1"
echo ""
echo "2. Verifica los logs en tiempo real:"
echo "   docker logs $CONTAINER -f"
echo ""
echo "3. Reinicia el contenedor si es necesario:"
echo "   docker restart $CONTAINER"
echo ""



