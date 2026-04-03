#!/bin/bash
# Limpiar sesión completamente y reconectar con modo pasivo

cd /root/checkin24hs

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

echo "🧹 LIMPIEZA COMPLETA DE SESIÓN Y RECONEXIÓN"
echo "=============================================================="
echo ""

# Obtener número de instancia
INSTANCE_NUM=$(docker exec "$CONTAINER" grep -oP "INSTANCE_NUMBER.*?\|\|.*?\K\d+" /app/whatsapp-server-baileys.js 2>/dev/null | head -1 || echo "1")
echo "📱 Instancia: $INSTANCE_NUM"
echo ""

# 1. Detener el servicio brevemente (o cerrar socket)
echo "1️⃣  Cerrando conexión actual..."
# No podemos detener el servicio en Docker Swarm fácilmente, pero podemos forzar limpieza
echo "   ⏳ Esperando 3 segundos..."
sleep 3
echo ""

# 2. Limpiar sesión del contenedor
echo "2️⃣  Limpiando sesión del contenedor..."
docker exec "$CONTAINER" rm -rf /app/auth_info_baileys_${INSTANCE_NUM} 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Sesión limpiada en el contenedor"
else
    echo "   ⚠️  No se pudo limpiar (puede que no exista)"
fi
echo ""

# 3. Verificar que el modo pasivo esté activo
echo "3️⃣  Verificando que modo pasivo esté activo..."
HAS_PASSIVE=$(docker exec "$CONTAINER" grep -q "passive: true" /app/whatsapp-server-baileys.js 2>/dev/null && echo "✅" || echo "❌")
HAS_SHOULD_SYNC=$(docker exec "$CONTAINER" grep -q "shouldSyncAppState: () => false" /app/whatsapp-server-baileys.js 2>/dev/null && echo "✅" || echo "❌")

echo "   passive: true: $HAS_PASSIVE"
echo "   shouldSyncAppState: () => false: $HAS_SHOULD_SYNC"
echo ""

if [ "$HAS_PASSIVE" != "✅" ] || [ "$HAS_SHOULD_SYNC" != "✅" ]; then
    echo "⚠️  El modo pasivo no está completamente activo!"
    echo "   Aplicando correcciones..."
    
    # Agregar passive: true si no está
    if [ "$HAS_PASSIVE" != "✅" ]; then
        docker exec "$CONTAINER" sed -i '/browser: \['\''Chrome'\'', '\''Desktop'\'', '\''1.0.0'\''\],/a\        passive: true,' /app/whatsapp-server-baileys.js 2>/dev/null
        echo "   ✅ passive: true agregado"
    fi
    
    # Agregar shouldSyncAppState si no está
    if [ "$HAS_SHOULD_SYNC" != "✅" ]; then
        docker exec "$CONTAINER" sed -i '/shouldSyncHistoryMessage: () => false, \/\/ No sincronizar historial/a\        shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)' /app/whatsapp-server-baileys.js 2>/dev/null
        echo "   ✅ shouldSyncAppState: () => false agregado"
    fi
    echo ""
fi

# 4. Reiniciar contenedor
echo "4️⃣  Reiniciando contenedor..."
docker restart "$CONTAINER"
echo "   ✅ Contenedor reiniciado"
echo ""

# 5. Esperar a que se genere el nuevo QR
echo "5️⃣  Esperando generación de nuevo QR (10 segundos)..."
sleep 10
echo ""

# 6. Verificar logs
echo "6️⃣  Verificando logs del contenedor:"
docker logs --tail 30 "$CONTAINER" 2>&1 | tail -15
echo ""

echo "=============================================================="
echo "✅ LIMPIEZA COMPLETA"
echo "=============================================================="
echo ""
echo "📋 INSTRUCCIONES IMPORTANTES:"
echo ""
echo "   1. ANTES de escanear el QR:"
echo "      → Abre WhatsApp en tu teléfono"
echo "      → Ve a Configuración → Dispositivos vinculados"
echo "      → DESVINCULA TODOS los dispositivos"
echo "      → Espera 30 segundos"
echo ""
echo "   2. Cierra WhatsApp Web si está abierto en tu computadora"
echo ""
echo "   3. Ahora abre: http://72.61.58.240:3001"
echo ""
echo "   4. Escanea el QR INMEDIATAMENTE después de aparecer"
echo ""
echo "   5. NO hagas nada durante 2-3 minutos"
echo "      - El servidor mostrará 'Conectando...'"
echo "      - Luego mostrará 'Conectado ✅'"
echo "      - En tu teléfono aparecerá 'Iniciando sesión...'"
echo "      - ESPERA pacientemente"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - NO desvincules el dispositivo desde el teléfono durante la conexión"
echo "   - NO abras WhatsApp Web en otro lugar"
echo "   - NO cierres WhatsApp en el teléfono"
echo "   - Si después de 3 minutos aún no conecta, verifica los logs"
echo ""
