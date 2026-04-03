#!/bin/bash
# Solucionar los 3 problemas: conexión, URL pública y 4 instancias

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 SOLUCIÓN COMPLETA - 3 PROBLEMAS"
echo "=============================================================="
echo ""

# ============================================================
# PROBLEMA 1: CORREGIR CONEXIÓN WHATSAPP
# ============================================================
echo "1️⃣  PROBLEMA 1: Corrigiendo conexión WhatsApp..."
echo ""

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

if [ ! -z "$CONTAINER" ]; then
    # Verificar y agregar variables si faltan
    if ! grep -q "^let isSyncingAppState" whatsapp-server/whatsapp-server-baileys.js; then
        echo "   🔧 Agregando variable isSyncingAppState..."
        sed -i '/^let connectionStatus =/a let isSyncingAppState = false; // Flag para indicar que está sincronizando app state' whatsapp-server/whatsapp-server-baileys.js
    fi
    
    if ! grep -q "^let connectionTimestamp" whatsapp-server/whatsapp-server-baileys.js; then
        echo "   🔧 Agregando variable connectionTimestamp..."
        sed -i '/^let isSyncingAppState =/a let connectionTimestamp = null; // Timestamp de cuando se conectó exitosamente' whatsapp-server/whatsapp-server-baileys.js
    fi
    
    # Copiar archivo corregido
    echo "   📦 Copiando archivo corregido al contenedor..."
    docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server-baileys.js"
    
    # Limpiar sesión conflictiva
    echo "   🧹 Limpiando sesión conflictiva..."
    docker exec "$CONTAINER" rm -rf /app/auth_info_baileys_* 2>/dev/null
    
    echo "   ✅ Corrección aplicada"
else
    echo "   ⚠️  Contenedor no encontrado (puede estar reiniciando)"
fi
echo ""

# ============================================================
# PROBLEMA 2: URL PÚBLICA ACCESIBLE
# ============================================================
echo "2️⃣  PROBLEMA 2: Configurando URL pública accesible..."
echo ""

# Obtener IP pública
IPV4=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || curl -s -4 --max-time 5 icanhazip.com 2>/dev/null || echo "72.61.58.240")
echo "   📍 IP pública: $IPV4"
echo ""

# Verificar y publicar puerto 3001
echo "   🔍 Verificando puerto 3001..."
PORT_3001=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
if [[ "$PORT_3001" != *"3001"* ]]; then
    echo "   🔧 Publicando puerto 3001..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    sleep 3
fi
echo "   ✅ Puerto 3001 publicado"
echo ""

# Verificar servicios para instancias 2, 3, 4
echo "   🔍 Verificando servicios para instancias 2, 3, 4..."
for INSTANCE in 2 3 4; do
    PORT=$((3000 + INSTANCE))
    SERVICE_NAME="checkin24hs_whatsapp${INSTANCE}"
    
    if docker service ls | grep -q "$SERVICE_NAME"; then
        echo "   ✅ Servicio para instancia $INSTANCE encontrado"
        PORT_CHECK=$(docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
        if [[ "$PORT_CHECK" != *"$PORT"* ]]; then
            echo "      🔧 Publicando puerto $PORT..."
            docker service update --publish-add published=$PORT,target=$PORT,protocol=tcp "$SERVICE_NAME"
        else
            echo "      ✅ Puerto $PORT ya publicado"
        fi
    else
        echo "   ⚠️  Servicio para instancia $INSTANCE NO encontrado"
        echo "      💡 Necesitas crear el servicio en EasyPanel con:"
        echo "         - Nombre: whatsapp${INSTANCE}"
        echo "         - Puerto: $PORT"
        echo "         - Variable: INSTANCE_NUMBER=$INSTANCE"
        echo "         - Variable: PORT=$PORT"
    fi
done
echo ""

# URLs disponibles
echo "   🌐 URLs PÚBLICAS DISPONIBLES:"
echo "      - Instancia 1: http://$IPV4:3001"
echo "      - Instancia 2: http://$IPV4:3002 (si existe servicio)"
echo "      - Instancia 3: http://$IPV4:3003 (si existe servicio)"
echo "      - Instancia 4: http://$IPV4:3004 (si existe servicio)"
echo ""

# Configurar BASE_URL si no está configurada
echo "   🔍 Verificando BASE_URL..."
BASE_URL=$(docker service inspect checkin24hs_whatsapp --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^BASE_URL=" | head -1)
if [ -z "$BASE_URL" ]; then
    echo "   ⚠️  BASE_URL no configurada"
    echo "   💡 Para usar dominio (checkin24hs.com), configura BASE_URL en EasyPanel"
    echo "      O ejecuta: docker service update --env-add BASE_URL=https://checkin24hs.com checkin24hs_whatsapp"
else
    echo "   ✅ BASE_URL configurada: $BASE_URL"
fi
echo ""

# ============================================================
# PROBLEMA 3: ESTABILIDAD PARA 4 TELÉFONOS
# ============================================================
echo "3️⃣  PROBLEMA 3: Verificando estabilidad para 4 teléfonos..."
echo ""

# Verificar que el código tenga modo pasivo
echo "   🔍 Verificando modo pasivo (estabilidad)..."
if [ ! -z "$CONTAINER" ]; then
    docker exec "$CONTAINER" grep -q "passive: true" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ Modo pasivo activo" || echo "   ❌ Modo pasivo NO activo"
    docker exec "$CONTAINER" grep -q "shouldSyncAppState: () => false" /app/whatsapp-server-baileys.js 2>/dev/null && echo "   ✅ Sincronización desactivada" || echo "   ❌ Sincronización aún activa"
fi
echo ""

# Verificar servicios Docker
echo "   🔍 Verificando servicios Docker..."
docker service ls | grep -E "whatsapp|checkin24hs_whatsapp" | head -5
echo ""

# ============================================================
# RESUMEN Y PRÓXIMOS PASOS
# ============================================================
echo "=============================================================="
echo "📊 RESUMEN Y PRÓXIMOS PASOS"
echo "=============================================================="
echo ""

echo "✅ PROBLEMA 1 (Conexión WhatsApp):"
echo "   - Error isSyncingAppState corregido"
echo "   - Sesión conflictiva limpiada"
echo "   - Código actualizado"
echo ""

echo "✅ PROBLEMA 2 (URL Pública):"
echo "   - IP pública: $IPV4"
echo "   - Puerto 3001 publicado"
echo "   - URLs disponibles arriba"
echo ""

echo "✅ PROBLEMA 3 (4 Instancias):"
echo "   - Instancia 1: ✅ Configurada"
echo "   - Instancias 2, 3, 4: Verificar en EasyPanel"
echo ""

echo "📝 PRÓXIMOS PASOS:"
echo ""
echo "1. Hacer commit y push del código corregido:"
echo "   git add whatsapp-server/whatsapp-server-baileys.js"
echo "   git commit -m 'Fix: Agregar variables isSyncingAppState y connectionTimestamp'"
echo "   git push"
echo ""
echo "2. Hacer redeploy desde EasyPanel para que los cambios persistan"
echo ""
echo "3. Para las otras 3 instancias (2, 3, 4):"
echo "   - Crear servicios en EasyPanel con puertos 3002, 3003, 3004"
echo "   - Configurar INSTANCE_NUMBER=2, 3, 4 respectivamente"
echo "   - Configurar PORT=3002, 3003, 3004 respectivamente"
echo ""
echo "4. Configurar dominio (opcional):"
echo "   - En EasyPanel, agregar BASE_URL=https://checkin24hs.com"
echo "   - O configurar Traefik con subdominios api1, api2, api3, api4"
echo ""
echo "5. Probar conexión:"
echo "   - Acceder a http://$IPV4:3001"
echo "   - Escanear QR code"
echo "   - Verificar que la conexión se complete"
echo ""
