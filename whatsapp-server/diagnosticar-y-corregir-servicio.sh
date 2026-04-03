#!/bin/bash
# Diagnosticar y corregir problemas del servicio

cd /root/checkin24hs

echo "=============================================================="
echo "🔍 DIAGNÓSTICO Y CORRECCIÓN DEL SERVICIO"
echo "=============================================================="
echo ""

# 1. Verificar logs recientes
echo "1️⃣  Verificando logs recientes..."
docker service logs checkin24hs_whatsapp --tail 50 | tail -20
echo ""

# 2. Verificar estado del servicio
echo "2️⃣  Verificando estado del servicio..."
docker service ps checkin24hs_whatsapp --no-trunc
echo ""

# 3. Verificar código en el contenedor
echo "3️⃣  Verificando código en el contenedor..."
CONTAINER_NAME=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)
if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ No se encontró contenedor corriendo"
    echo "   Intentando obtener contenedor del servicio..."
    CONTAINER_NAME=$(docker service ps checkin24hs_whatsapp -q --filter "desired-state=running" | head -1)
    if [ ! -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME=$(docker ps -q --filter "name=checkin24hs_whatsapp")
    fi
fi

if [ ! -z "$CONTAINER_NAME" ]; then
    echo "📦 Contenedor: $CONTAINER_NAME"
    echo ""
    echo "   Verificando archivo en contenedor:"
    docker exec "$CONTAINER_NAME" ls -la /app/whatsapp-server/whatsapp-server-baileys.js 2>/dev/null && echo "✅ Archivo existe" || echo "❌ Archivo no existe"
    echo ""
    echo "   Verificando passive: true:"
    docker exec "$CONTAINER_NAME" grep -q "passive: true" /app/whatsapp-server/whatsapp-server-baileys.js 2>/dev/null && echo "✅ passive: true encontrado" || echo "❌ passive: true NO encontrado"
    echo ""
    echo "   Verificando procesos Node.js:"
    docker exec "$CONTAINER_NAME" ps aux | grep -E "node|npm" | grep -v grep || echo "❌ No hay procesos Node.js"
else
    echo "❌ No se pudo encontrar contenedor"
fi
echo ""

# 4. Verificar puerto publicado
echo "4️⃣  Verificando puerto publicado..."
PORT_MAPPING=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{end}}' 2>/dev/null)
if [ -z "$PORT_MAPPING" ]; then
    echo "❌ Puerto NO está publicado"
    echo ""
    echo "🔧 Publicando puerto 3001..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    echo "✅ Puerto 3001 publicado"
    sleep 5
    echo ""
    echo "   Verificando nuevamente..."
    PORT_MAPPING=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{end}}' 2>/dev/null)
    echo "   Mapeo actual: $PORT_MAPPING"
else
    echo "✅ Puerto publicado: $PORT_MAPPING"
fi
echo ""

# 5. Verificar código local vs contenedor
echo "5️⃣  Comparando código local vs contenedor..."
if [ ! -z "$CONTAINER_NAME" ]; then
    echo "   Código local tiene passive: true?"
    grep -q "passive: true" whatsapp-server/whatsapp-server-baileys.js && echo "   ✅ Sí" || echo "   ❌ No"
    echo ""
    echo "   Código en contenedor tiene passive: true?"
    docker exec "$CONTAINER_NAME" grep -q "passive: true" /app/whatsapp-server/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ Sí" || echo "   ❌ No"
    echo ""
    if grep -q "passive: true" whatsapp-server/whatsapp-server-baileys.js && ! docker exec "$CONTAINER_NAME" grep -q "passive: true" /app/whatsapp-server/whatsapp-server-baileys.js 2>/dev/null; then
        echo "⚠️  El código local está actualizado pero el contenedor NO"
        echo "   Esto significa que el redeploy no usó la nueva imagen"
        echo ""
        echo "🔧 SOLUCIÓN:"
        echo "   1. Verificar que EasyPanel haya hecho rebuild de la imagen"
        echo "   2. O aplicar cambios directamente en el contenedor (temporal)"
        echo ""
        read -p "¿Aplicar cambios directamente en el contenedor? (s/n): " respuesta
        if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
            echo "   Aplicando cambios en el contenedor..."
            docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER_NAME:/app/whatsapp-server/whatsapp-server-baileys.js"
            echo "   ✅ Archivo copiado"
            echo "   Reiniciando proceso Node.js..."
            docker exec "$CONTAINER_NAME" pkill -f node || echo "   No se pudo reiniciar (puede reiniciarse automáticamente)"
        fi
    fi
fi
echo ""

# 6. Resumen
echo "=============================================================="
echo "📊 RESUMEN"
echo "=============================================================="
echo ""
echo "Si el código no está actualizado en el contenedor:"
echo "   1. Verificar que EasyPanel haya hecho rebuild de la imagen"
echo "   2. Verificar que el repositorio GitHub tenga los últimos cambios"
echo "   3. Hacer redeploy completo desde EasyPanel"
echo ""
echo "Si el puerto no está publicado:"
echo "   Ya se intentó publicarlo. Verificar con:"
echo "   docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}{{end}}'"
echo ""
