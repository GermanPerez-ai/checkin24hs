#!/bin/bash
# 🔧 Aplicar cambios al contenedor y verificar

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 APLICANDO CAMBIOS AL CONTENEDOR"
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

# Verificar si hay volúmenes montados
echo "2️⃣  Verificando volúmenes montados..."
docker inspect $CONTAINER_ID | grep -A 10 "Mounts" | grep -E "Source|Destination" | head -10
echo ""

# Verificar archivo local
echo "3️⃣  Verificando archivo local..."
if grep -q "connectionTimestamp = null" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ Archivo local tiene connectionTimestamp"
    grep -n "connectionTimestamp = null" whatsapp-server/whatsapp-server-baileys.js | head -1
else
    echo "   ❌ Archivo local NO tiene connectionTimestamp"
    exit 1
fi
echo ""

# Copiar archivo
echo "4️⃣  Copiando archivo al contenedor..."
docker cp whatsapp-server/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado exitosamente"
else
    echo "   ❌ Error copiando archivo"
    exit 1
fi
echo ""

# Verificar que se copió correctamente
echo "5️⃣  Verificando que se copió correctamente..."
if docker exec $CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ connectionTimestamp encontrado en contenedor"
    docker exec $CONTAINER_ID sh -c "grep -n 'connectionTimestamp = null' /app/whatsapp-server-baileys.js | head -1"
else
    echo "   ❌ connectionTimestamp NO encontrado en contenedor"
    echo "   ⚠️  El archivo no se copió correctamente"
    exit 1
fi
echo ""

# Reiniciar contenedor
echo "6️⃣  Reiniciando contenedor..."
docker restart $CONTAINER_ID

if [ $? -eq 0 ]; then
    echo "   ✅ Contenedor reiniciado"
else
    echo "   ❌ Error reiniciando contenedor"
    exit 1
fi
echo ""

# Esperar a que inicie
echo "7️⃣  Esperando 60 segundos para que el contenedor inicie..."
sleep 60
echo "   ✅ Espera completada"
echo ""

# Verificar que el archivo sigue ahí después del reinicio
echo "8️⃣  Verificando que el archivo sigue después del reinicio..."
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$NEW_CONTAINER_ID" ]; then
    echo "   ⚠️  No se encontró el contenedor después del reinicio"
    exit 1
fi

echo "   Nuevo contenedor: $NEW_CONTAINER_ID"
echo ""

if docker exec $NEW_CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ connectionTimestamp encontrado después del reinicio"
    docker exec $NEW_CONTAINER_ID sh -c "grep -n 'connectionTimestamp = null' /app/whatsapp-server-baileys.js | head -1"
else
    echo "   ❌ connectionTimestamp NO encontrado después del reinicio"
    echo "   ⚠️  El contenedor volvió a la imagen antigua"
    echo ""
    echo "   💡 Esto significa que el archivo se monta desde un volumen o"
    echo "      el contenedor se reconstruye desde la imagen de Docker"
    echo ""
    echo "   🔧 SOLUCIÓN: Necesitas actualizar la imagen de Docker o"
    echo "      configurar un volumen persistente"
    exit 1
fi
echo ""

# Verificar que el servidor responde
echo "9️⃣  Verificando que el servidor responde..."
HEALTH=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde: $HEALTH"
else
    echo "   ⚠️  Servidor no responde aún (puede tardar más)"
fi
echo ""

echo "=============================================================="
echo "✅ PROCESO COMPLETADO"
echo "=============================================================="
echo ""
