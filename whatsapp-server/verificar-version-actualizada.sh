#!/bin/bash
# ✅ Verificar que el contenedor tiene la versión actualizada del código

echo "=============================================================="
echo "🔍 VERIFICANDO VERSIÓN ACTUALIZADA EN CONTENEDOR"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró el contenedor"
    exit 1
fi

echo "1️⃣  Contenedor actual: $CONTAINER_ID"
echo ""

# Verificar que tiene connectionTimestamp
echo "2️⃣  Verificando variable connectionTimestamp..."
if docker exec $CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ connectionTimestamp encontrado"
    docker exec $CONTAINER_ID sh -c "grep -n 'connectionTimestamp' /app/whatsapp-server-baileys.js | head -3"
else
    echo "   ❌ connectionTimestamp NO encontrado"
    echo "   ⚠️  El contenedor tiene una versión ANTIGUA"
fi
echo ""

# Verificar protección mejorada (minutesSinceConnection < 15)
echo "3️⃣  Verificando protección mejorada (15 minutos)..."
if docker exec $CONTAINER_ID sh -c "grep -q 'minutesSinceConnection < 15' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ Protección de 15 minutos encontrada"
    docker exec $CONTAINER_ID sh -c "grep -n 'minutesSinceConnection < 15' /app/whatsapp-server-baileys.js"
else
    echo "   ❌ Protección de 15 minutos NO encontrada"
    echo "   ⚠️  El contenedor tiene una versión ANTIGUA"
fi
echo ""

# Verificar reseteo de timestamp al limpiar sesión
echo "4️⃣  Verificando reseteo de timestamp al limpiar sesión..."
if docker exec $CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js" && \
   docker exec $CONTAINER_ID sh -c "grep -A2 'Sesión limpiada completamente' /app/whatsapp-server-baileys.js | grep -q 'connectionTimestamp = null'"; then
    echo "   ✅ Reseteo de timestamp encontrado"
    docker exec $CONTAINER_ID sh -c "grep -A3 'Sesión limpiada completamente' /app/whatsapp-server-baileys.js | head -4"
else
    echo "   ⚠️  Reseteo de timestamp puede no estar completo"
fi
echo ""

# Verificar que tiene la protección durante sincronización
echo "5️⃣  Verificando protección durante sincronización..."
if docker exec $CONTAINER_ID sh -c "grep -q 'Error durante sincronización del app state' /app/whatsapp-server-baileys.js"; then
    echo "   ✅ Protección durante sincronización encontrada"
    docker exec $CONTAINER_ID sh -c "grep -B2 -A2 'Error durante sincronización' /app/whatsapp-server-baileys.js | head -6"
else
    echo "   ❌ Protección durante sincronización NO encontrada"
fi
echo ""

# Comparar número de líneas
echo "6️⃣  Comparando número de líneas..."
LOCAL_LINES=$(wc -l < /root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js)
CONTAINER_LINES=$(docker exec $CONTAINER_ID sh -c "wc -l < /app/whatsapp-server-baileys.js")
echo "   Archivo local: $LOCAL_LINES líneas"
echo "   Archivo contenedor: $CONTAINER_LINES líneas"
if [ "$LOCAL_LINES" -eq "$CONTAINER_LINES" ]; then
    echo "   ✅ Número de líneas coincide"
else
    echo "   ⚠️  Número de líneas NO coincide (diferencia: $((LOCAL_LINES - CONTAINER_LINES)))"
fi
echo ""

# Verificar checksum (si es posible)
echo "7️⃣  Verificando integridad del archivo..."
LOCAL_CHECKSUM=$(md5sum /root/checkin24hs/whatsapp-server/whatsapp-server-baileys.js 2>/dev/null | awk '{print $1}')
CONTAINER_CHECKSUM=$(docker exec $CONTAINER_ID sh -c "md5sum /app/whatsapp-server-baileys.js 2>/dev/null" | awk '{print $1}')

if [ -n "$LOCAL_CHECKSUM" ] && [ -n "$CONTAINER_CHECKSUM" ]; then
    if [ "$LOCAL_CHECKSUM" = "$CONTAINER_CHECKSUM" ]; then
        echo "   ✅ Checksums coinciden - archivos idénticos"
    else
        echo "   ⚠️  Checksums NO coinciden - archivos diferentes"
        echo "   Local: $LOCAL_CHECKSUM"
        echo "   Contenedor: $CONTAINER_CHECKSUM"
    fi
else
    echo "   ⚠️  No se pudo calcular checksum (md5sum no disponible)"
fi
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""

# Resumen
echo "📊 RESUMEN:"
echo ""

ALL_OK=true

if ! docker exec $CONTAINER_ID sh -c "grep -q 'connectionTimestamp = null' /app/whatsapp-server-baileys.js" 2>/dev/null; then
    echo "   ❌ connectionTimestamp: NO encontrado"
    ALL_OK=false
else
    echo "   ✅ connectionTimestamp: encontrado"
fi

if ! docker exec $CONTAINER_ID sh -c "grep -q 'minutesSinceConnection < 15' /app/whatsapp-server-baileys.js" 2>/dev/null; then
    echo "   ❌ Protección 15 min: NO encontrada"
    ALL_OK=false
else
    echo "   ✅ Protección 15 min: encontrada"
fi

if ! docker exec $CONTAINER_ID sh -c "grep -q 'Error durante sincronización' /app/whatsapp-server-baileys.js" 2>/dev/null; then
    echo "   ❌ Protección sincronización: NO encontrada"
    ALL_OK=false
else
    echo "   ✅ Protección sincronización: encontrada"
fi

echo ""

if [ "$ALL_OK" = true ]; then
    echo "✅ El contenedor tiene la versión ACTUALIZADA"
    echo "   Puedes proceder a probar la conexión"
else
    echo "❌ El contenedor NO tiene la versión actualizada"
    echo "   Necesitas copiar el archivo nuevamente:"
    echo ""
    echo "   docker cp whatsapp-server/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js"
    echo "   docker restart $CONTAINER_ID"
fi
echo ""
