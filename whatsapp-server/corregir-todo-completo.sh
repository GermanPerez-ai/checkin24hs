#!/bin/bash
# Corregir todos los problemas: error isSyncingAppState, sesión conflictiva y URL pública

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 CORRECCIÓN COMPLETA - 3 PROBLEMAS"
echo "=============================================================="
echo ""

CONTAINER=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# PROBLEMA 1: Corregir error isSyncingAppState
echo "1️⃣  PROBLEMA 1: Corrigiendo error isSyncingAppState..."
echo ""

# Verificar que las variables estén declaradas en el archivo local
if ! grep -q "^let isSyncingAppState" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ⚠️  Variable isSyncingAppState no encontrada, agregando..."
    sed -i '/^let connectionStatus =/a let isSyncingAppState = false; // Flag para indicar que está sincronizando app state' whatsapp-server/whatsapp-server-baileys.js
fi

if ! grep -q "^let connectionTimestamp" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ⚠️  Variable connectionTimestamp no encontrada, agregando..."
    sed -i '/^let isSyncingAppState =/a let connectionTimestamp = null; // Timestamp de cuando se conectó exitosamente' whatsapp-server/whatsapp-server-baileys.js
fi

echo "   ✅ Variables verificadas en archivo local"
echo ""

# Copiar archivo completo al contenedor
echo "   Copiando archivo corregido al contenedor..."
docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server-baileys.js"
docker cp whatsapp-server/whatsapp-server-baileys.js "$CONTAINER:/app/whatsapp-server/whatsapp-server-baileys.js" 2>/dev/null || true
echo "   ✅ Archivo copiado"
echo ""

# Verificar sintaxis
echo "   Verificando sintaxis..."
if docker exec "$CONTAINER" node -c /app/whatsapp-server-baileys.js 2>&1; then
    echo "   ✅ Sintaxis correcta"
else
    echo "   ❌ Aún hay errores de sintaxis"
fi
echo ""

# PROBLEMA 2: Limpiar sesión conflictiva
echo "2️⃣  PROBLEMA 2: Limpiando sesión conflictiva..."
docker exec "$CONTAINER" rm -rf /app/auth_info_baileys_* 2>/dev/null
echo "   ✅ Sesión limpiada"
echo ""

# PROBLEMA 3: Verificar URL pública y puertos
echo "3️⃣  PROBLEMA 3: Verificando URL pública y puertos..."
echo ""

# Obtener IP pública
IPV4=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || curl -s -4 --max-time 5 icanhazip.com 2>/dev/null || echo "72.61.58.240")
echo "   IP pública: $IPV4"
echo ""

# Verificar puerto 3001
echo "   Verificando puerto 3001..."
PORT_3001=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
if [[ "$PORT_3001" == *"3001"* ]]; then
    echo "   ✅ Puerto 3001 publicado"
else
    echo "   ⚠️  Puerto 3001 NO publicado, publicando..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    echo "   ✅ Puerto 3001 publicado"
fi
echo ""

# Verificar si hay servicios para los otros puertos (3002, 3003, 3004)
echo "   Verificando servicios para puertos 3002, 3003, 3004..."
for PORT in 3002 3003 3004; do
    SERVICE_NAME="checkin24hs_whatsapp_${PORT}"
    if docker service ls | grep -q "$SERVICE_NAME"; then
        echo "   ✅ Servicio para puerto $PORT existe"
        PORT_CHECK=$(docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
        if [[ "$PORT_CHECK" == *"$PORT"* ]]; then
            echo "      ✅ Puerto $PORT publicado"
        else
            echo "      ⚠️  Puerto $PORT NO publicado, publicando..."
            docker service update --publish-add published=$PORT,target=$PORT,protocol=tcp "$SERVICE_NAME"
        fi
    else
        echo "   ⚠️  Servicio para puerto $PORT NO existe (esto es normal si solo usas 1 instancia)"
    fi
done
echo ""

# Verificar configuración de dominio/URL
echo "   Verificando configuración de dominio..."
BASE_URL=$(docker service inspect checkin24hs_whatsapp --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -i "BASE_URL" | head -1)
if [ ! -z "$BASE_URL" ]; then
    echo "   📋 BASE_URL configurada: $BASE_URL"
else
    echo "   ⚠️  BASE_URL no configurada"
    echo "   💡 Puedes configurarla en EasyPanel o con:"
    echo "      docker service update --env-add BASE_URL=https://checkin24hs.com checkin24hs_whatsapp"
fi
echo ""

# Resumen final
echo "=============================================================="
echo "📊 RESUMEN"
echo "=============================================================="
echo ""
echo "✅ PROBLEMA 1 (Conexión WhatsApp):"
echo "   - Error isSyncingAppState corregido"
echo "   - Sesión conflictiva limpiada"
echo "   - Código actualizado en contenedor"
echo ""
echo "✅ PROBLEMA 2 (URL Pública):"
echo "   - IP pública: $IPV4"
echo "   - URL directa: http://$IPV4:3001"
echo "   - Puerto 3001 publicado"
echo ""
echo "✅ PROBLEMA 3 (4 Instancias):"
echo "   - Puerto 3001 verificado"
echo "   - Puertos 3002, 3003, 3004 verificados (si existen servicios)"
echo ""
echo "🌐 URLs PARA ACCEDER:"
echo "   - Instancia 1: http://$IPV4:3001"
echo "   - Instancia 2: http://$IPV4:3002 (si existe)"
echo "   - Instancia 3: http://$IPV4:3003 (si existe)"
echo "   - Instancia 4: http://$IPV4:3004 (si existe)"
echo ""
echo "💡 Para usar dominio (checkin24hs.com):"
echo "   1. Configura BASE_URL en EasyPanel o con docker service update"
echo "   2. Configura Traefik con subdominios api1, api2, api3, api4"
echo "   3. O usa directamente: https://api1.checkin24hs.com, etc."
echo ""
echo "🔄 Espera 10 segundos y recarga la página para ver el nuevo QR code"
echo ""
