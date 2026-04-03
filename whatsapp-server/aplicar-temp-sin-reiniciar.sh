#!/bin/bash
# 🔧 Aplicar cambios temporalmente sin reiniciar (para probar)

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 APLICANDO CAMBIOS TEMPORALES (SIN REINICIAR)"
echo "=============================================================="
echo ""

# Obtener contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "1️⃣  Contenedor actual: $CONTAINER_ID"
echo ""

# Verificar archivo local
echo "2️⃣  Verificando archivo local..."
if grep -q "connectionTimestamp = null" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ Archivo local tiene connectionTimestamp"
else
    echo "   ❌ Archivo local NO tiene connectionTimestamp"
    exit 1
fi
echo ""

# Copiar archivo
echo "3️⃣  Copiando archivo al contenedor..."
docker cp whatsapp-server/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado exitosamente"
else
    echo "   ❌ Error copiando archivo"
    exit 1
fi
echo ""

# Verificar que se copió
echo "4️⃣  Verificando que se copió..."
if docker exec $CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ connectionTimestamp encontrado"
    docker exec $CONTAINER_ID sh -c "grep -n 'connectionTimestamp = null' /app/whatsapp-server-baileys.js | head -1"
else
    echo "   ❌ connectionTimestamp NO encontrado"
    exit 1
fi
echo ""

# Reiniciar solo el proceso Node.js dentro del contenedor (no el contenedor completo)
echo "5️⃣  Reiniciando proceso Node.js dentro del contenedor..."
# Buscar el proceso Node.js
NODE_PID=$(docker exec $CONTAINER_ID sh -c "ps aux | grep 'node whatsapp-server' | grep -v grep | awk '{print \$2}' | head -1")

if [ -n "$NODE_PID" ]; then
    echo "   Proceso Node.js encontrado: PID $NODE_PID"
    echo "   Enviando señal SIGTERM para reiniciar suavemente..."
    docker exec $CONTAINER_ID sh -c "kill -TERM $NODE_PID 2>/dev/null || true"
    echo "   ✅ Señal enviada"
    echo "   ⏳ Esperando 10 segundos para que el proceso se reinicie..."
    sleep 10
else
    echo "   ⚠️  No se encontró el proceso Node.js"
    echo "   El contenedor puede estar usando un script de inicio que lo reinicia automáticamente"
fi
echo ""

# Verificar que el servidor responde
echo "6️⃣  Verificando que el servidor responde..."
sleep 5
HEALTH=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde: $HEALTH"
else
    echo "   ⚠️  Servidor no responde aún"
    echo "   💡 Puede tardar unos segundos más en reiniciar"
fi
echo ""

echo "=============================================================="
echo "✅ PROCESO COMPLETADO"
echo "=============================================================="
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Estos cambios son TEMPORALES"
echo "   - Se perderán si el contenedor se reinicia"
echo "   - Para hacerlos permanentes, sube los cambios a GitHub y"
echo "     haz un redeploy desde EasyPanel"
echo ""
