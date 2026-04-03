#!/bin/bash
# ✅ Verificar que el contenedor mantiene el archivo después del reinicio

cd /root/checkin24hs

echo "=============================================================="
echo "🔍 VERIFICANDO DESPUÉS DEL REINICIO"
echo "=============================================================="
echo ""

# Obtener contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "1️⃣  Contenedor actual: $CONTAINER_ID"
echo ""

# Verificar connectionTimestamp
echo "2️⃣  Verificando connectionTimestamp..."
if docker exec $CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ connectionTimestamp encontrado"
    docker exec $CONTAINER_ID sh -c "grep -n 'connectionTimestamp = null' /app/whatsapp-server-baileys.js | head -1"
else
    echo "   ❌ connectionTimestamp NO encontrado"
    echo "   ⚠️  El contenedor volvió a la imagen antigua"
    echo ""
    echo "   💡 Esto significa que Docker Swarm está recreando el contenedor"
    echo "      desde la imagen antigua en lugar de usar el archivo copiado"
    echo ""
    echo "   🔧 SOLUCIÓN: Necesitas actualizar la imagen de Docker o"
    echo "      hacer un redeploy desde EasyPanel con el código actualizado"
    exit 1
fi
echo ""

# Verificar protección de 15 minutos
echo "3️⃣  Verificando protección de 15 minutos..."
if docker exec $CONTAINER_ID sh -c "grep -q 'minutesSinceConnection < 15' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ Protección de 15 minutos encontrada"
    docker exec $CONTAINER_ID sh -c "grep -n 'minutesSinceConnection < 15' /app/whatsapp-server-baileys.js"
else
    echo "   ❌ Protección de 15 minutos NO encontrada"
fi
echo ""

# Verificar protección durante sincronización
echo "4️⃣  Verificando protección durante sincronización..."
if docker exec $CONTAINER_ID sh -c "grep -q 'Error durante sincronización del app state' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ Protección durante sincronización encontrada"
    docker exec $CONTAINER_ID sh -c "grep -n 'Error durante sincronización del app state' /app/whatsapp-server-baileys.js"
else
    echo "   ❌ Protección durante sincronización NO encontrada"
fi
echo ""

# Verificar que el servidor responde
echo "5️⃣  Verificando que el servidor responde..."
HEALTH=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde: $HEALTH"
else
    echo "   ⚠️  Servidor no responde aún (puede tardar más)"
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
