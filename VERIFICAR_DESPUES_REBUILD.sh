#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN COMPLETA DESPUÉS DE REBUILD"
echo "=========================================="
echo ""

# 1. Verificar contenedor activo
echo "1️⃣ Verificando contenedor activo..."
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 2. Verificar logs recientes
echo "2️⃣ Logs recientes (últimas 15 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 15 2>&1
echo ""

# 3. Verificar Traefik
echo "3️⃣ Verificando Traefik:"
echo "----------------------------------------"
SERVICE_NAME=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "⚠️ No se encontró servicio Docker Swarm"
    TRAEFIK_OK=0
else
    echo "✅ Servicio: $SERVICE_NAME"
    echo ""
    TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "traefik")
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo "❌ No se encontraron labels de Traefik"
        TRAEFIK_OK=0
    else
        echo "✅ Labels de Traefik encontradas:"
        echo "$TRAEFIK_LABELS" | head -7
        TRAEFIK_OK=1
    fi
fi
echo ""

# 4. Configurar Traefik si falta
if [ "$TRAEFIK_OK" = "0" ] && [ -n "$SERVICE_NAME" ]; then
    echo "=========================================="
    echo "🔧 CONFIGURANDO TRAEFIK AUTOMÁTICAMENTE"
    echo "=========================================="
    echo ""
    docker service update \
      --label-add 'traefik.enable=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
      --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
      --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
      "$SERVICE_NAME" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Labels de Traefik agregadas"
        echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
        sleep 15
        TRAEFIK_OK=1
    else
        echo "❌ Error configurando Traefik"
    fi
    echo ""
fi

# 5. Probar endpoints internos
echo "4️⃣ Endpoints internos (desde el contenedor):"
echo "----------------------------------------"
echo "📊 /api/health:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/health',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log(d))}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\"" 2>&1 | head -3
echo ""

echo "📊 /api/status:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR:',data.qrCode?'Disponible':'No disponible')}catch(e){console.log('Error parseando:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

# 6. Probar endpoints externos (vía Traefik)
echo "5️⃣ Endpoints externos (vía Traefik):"
echo "----------------------------------------"
echo "🌐 https://api1.checkin24hs.com/api/health:"
HEALTH_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/api/health 2>&1)
HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_STATUS")
if [ "$HEALTH_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $HEALTH_STATUS"
    echo "$HEALTH_BODY" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_BODY"
else
    echo "❌ HTTP Status: $HEALTH_STATUS"
    echo "$HEALTH_BODY" | head -3
fi
echo ""

echo "🌐 https://api1.checkin24hs.com/api/status:"
STATUS_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/api/status 2>&1)
STATUS_CODE=$(echo "$STATUS_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
STATUS_BODY=$(echo "$STATUS_RESPONSE" | grep -v "HTTP_STATUS")
if [ "$STATUS_CODE" = "200" ]; then
    echo "✅ HTTP Status: $STATUS_CODE"
    echo "$STATUS_BODY" | python3 -m json.tool 2>/dev/null | head -10 || echo "$STATUS_BODY" | head -5
else
    echo "❌ HTTP Status: $STATUS_CODE"
    echo "$STATUS_BODY" | head -3
fi
echo ""

echo "🌐 https://api1.checkin24hs.com/ (root):"
ROOT_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://api1.checkin24hs.com/ 2>&1)
if [ "$ROOT_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $ROOT_STATUS (Página HTML disponible)"
else
    echo "❌ HTTP Status: $ROOT_STATUS"
fi
echo ""

# 7. Verificar eventos importantes
echo "6️⃣ Eventos importantes en logs:"
echo "----------------------------------------"
echo "📱 QR Codes:"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -E "(QR Code recibido|QR Code generado|pairing configured)" | tail -3
echo ""
echo "🔄 Conexiones:"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -E "(WhatsApp conectado|Teléfono conectado|Error 515|restart required)" | tail -5
echo ""
echo "❌ Errores recientes:"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -E "(Error|error|device_removed)" | tail -5
echo ""

# 8. Resumen
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "✅ Contenedor: $CONTAINER_ID"
echo "✅ Servicio: ${SERVICE_NAME:-'N/A'}"
if [ "$TRAEFIK_OK" = "1" ]; then
    echo "✅ Traefik: Configurado y funcionando"
else
    echo "❌ Traefik: No configurado"
fi

# Verificar estado de conexión
echo ""
echo "📱 Estado de WhatsApp:"
STATUS_DATA=$(docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log(JSON.stringify({connected:data.connected||data.whatsapp==='connected'||data.whatsapp==='open',hasQR:!!data.qrCode,phone:data.phone||null},null,2))}catch(e){console.log('{}')}})}).on('error',()=>console.log('{}'));setTimeout(()=>process.exit(0),3000);\"" 2>&1 | tail -5)
if echo "$STATUS_DATA" | grep -q "connected.*true"; then
    echo "   ✅ Conectado"
    PHONE=$(echo "$STATUS_DATA" | grep -o '"phone":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$PHONE" ] && [ "$PHONE" != "null" ]; then
        echo "   📱 Teléfono: $PHONE"
    fi
elif echo "$STATUS_DATA" | grep -q "hasQR.*true"; then
    echo "   ⏳ Esperando escanear QR code"
    echo "   💡 Abre https://api1.checkin24hs.com/ para ver el QR"
else
    echo "   ⚠️ Desconectado - Generando QR code..."
    echo "   💡 Espera 30-60 segundos"
fi

echo ""
echo "💡 Próximos pasos:"
echo "   1. Si no hay QR code, espera 30-60 segundos"
echo "   2. Abre https://api1.checkin24hs.com/ en el navegador"
echo "   3. IMPORTANTE: Desvincula TODOS los dispositivos vinculados antes de escanear"
echo "   4. Escanea el QR lo más rápido posible"
echo "   5. El error 515 es normal, el servidor se reconectará automáticamente"
echo ""
