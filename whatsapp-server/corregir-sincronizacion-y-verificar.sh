#!/bin/bash
# Corregir sincronización y verificar que todo esté bien

cd /root/checkin24hs

echo "🔧 Corrigiendo sincronización y verificando todo..."
echo ""

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

if [ ! -z "$CONTAINER" ]; then
    # Verificar archivo local
    echo "1️⃣  Verificando archivo local..."
    grep -q "shouldSyncAppState: () => false" whatsapp-server/whatsapp-server-baileys.js && echo "   ✅ shouldSyncAppState: () => false encontrado en local" || echo "   ❌ NO encontrado en local"
    echo ""
    
    # Copiar archivo completo
    echo "2️⃣  Copiando archivo completo al contenedor..."
    docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server-baileys.js"
    echo "   ✅ Archivo copiado"
    echo ""
    
    # Verificar en contenedor
    echo "3️⃣  Verificando en contenedor..."
    docker exec "$CONTAINER" grep -q "shouldSyncAppState: () => false" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ shouldSyncAppState: () => false encontrado en contenedor" || echo "   ❌ NO encontrado en contenedor"
    docker exec "$CONTAINER" grep -q "passive: true" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ passive: true encontrado en contenedor" || echo "   ❌ passive: true NO encontrado en contenedor"
    docker exec "$CONTAINER" grep -q "fireInitQueries: false" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ fireInitQueries: false encontrado en contenedor" || echo "   ❌ fireInitQueries: false NO encontrado en contenedor"
    echo ""
    
    # Verificar sintaxis
    echo "4️⃣  Verificando sintaxis..."
    docker exec "$CONTAINER" node -c /app/whatsapp-server-baileys.js 2>&1 && echo "   ✅ Sintaxis correcta" || echo "   ❌ Error de sintaxis"
    echo ""
else
    echo "❌ Contenedor no encontrado"
fi

echo ""
echo "=============================================================="
echo "📊 INFORMACIÓN IMPORTANTE"
echo "=============================================================="
echo ""
echo "✅ CONEXIÓN DESDE SERVIDOR ONLINE:"
echo "   - El servidor corre en: srv1152402 (servidor remoto)"
echo "   - IP pública: 72.61.58.240"
echo "   - Los teléfonos se conectan al SERVIDOR, no a tu PC"
echo "   - Si apagas tu computadora, los teléfonos SIGUEN CONECTADOS"
echo "   - El servidor sigue corriendo 24/7"
echo ""
echo "🌐 URL PÚBLICA:"
echo "   http://72.61.58.240:3001"
echo ""
echo "💡 Para que los cambios persistan después de reinicios:"
echo "   1. git add whatsapp-server/whatsapp-server-baileys.js"
echo "   2. git commit -m 'Fix: Modo pasivo completo'"
echo "   3. git push"
echo "   4. Redeploy desde EasyPanel"
echo ""
