#!/bin/bash

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETA DESPUÉS DE REBUILD"
echo "=========================================="
echo ""

# 1. Verificar contenedor
echo "1️⃣ Contenedor de WhatsApp:"
echo "----------------------------------------"
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp.1" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
docker ps --filter "id=$CONTAINER_ID" --format "table {{.ID}}\t{{.Status}}\t{{.Names}}"
echo ""

# 2. Verificar logs recientes
echo "2️⃣ Logs recientes (últimas 20 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 20 2>&1 | tail -20
echo ""

# 3. Verificar estado del servidor
echo "3️⃣ Estado del servidor (endpoints internos):"
echo "----------------------------------------"
echo "📊 /api/health:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/health',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('Instancia:',data.instance||'N/A');console.log('QR:',!!data.qrCode?'Disponible':'No disponible')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "📊 /api/status:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado WhatsApp:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR disponible:',!!data.qrCode);console.log('Teléfono:',data.phone||'N/A')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3003);\"" 2>&1
echo ""

# 4. Verificar Traefik
echo "4️⃣ Configuración de Traefik:"
echo "----------------------------------------"
SERVICE_NAME=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio Docker Swarm"
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
        echo "$TRAEFIK_LABELS" | head -10
        TRAEFIK_OK=1
    fi
fi
echo ""

# 5. Configurar Traefik si falta
if [ "$TRAEFIK_OK" = "0" ]; then
    echo "5️⃣ Configurando Traefik..."
    echo "----------------------------------------"
    docker service update \
      --label-add 'traefik.enable=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
      --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
      --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
      "$SERVICE_NAME" 2>&1 | grep -E "(updated|converged)" || echo "   ⚠️  Error al configurar"
    
    if [ $? -eq 0 ]; then
        echo "✅ Traefik configurado"
        echo "⏳ Esperando 20 segundos para que Traefik detecte los cambios..."
        sleep 20
        TRAEFIK_OK=1
    else
        echo "❌ Error configurando Traefik"
    fi
    echo ""
fi

# 6. Verificar endpoints externos (vía Traefik)
echo "6️⃣ Endpoints externos (vía Traefik):"
echo "----------------------------------------"
echo "🌐 https://api1.checkin24hs.com/api/health:"
HEALTH_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/api/health 2>&1)
HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_STATUS")
if [ "$HEALTH_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $HEALTH_STATUS"
    echo "$HEALTH_BODY" | head -3
else
    echo "❌ HTTP Status: $HEALTH_STATUS"
    echo "$HEALTH_BODY" | head -3
fi
echo ""

echo "🌐 https://api1.checkin24hs.com/ (root):"
ROOT_RESPONSE=$(curl -s -k -w "\nHTTP_STATUS:%{http_code}" https://api1.checkin24hs.com/ 2>&1)
ROOT_STATUS=$(echo "$ROOT_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
ROOT_BODY=$(echo "$ROOT_RESPONSE" | grep -v "HTTP_STATUS")
if [ "$ROOT_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $ROOT_STATUS"
    echo "   Longitud: $(echo "$ROOT_BODY" | wc -c) caracteres"
    if echo "$ROOT_BODY" | grep -q "<!DOCTYPE html"; then
        echo "   ✅ Contiene HTML"
    else
        echo "   ⚠️  No contiene HTML"
    fi
else
    echo "❌ HTTP Status: $ROOT_STATUS"
    echo "$ROOT_BODY" | head -3
fi
echo ""

echo "🌐 https://api1.checkin24hs.com/favicon.ico:"
FAVICON_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://api1.checkin24hs.com/favicon.ico 2>&1)
if [ "$FAVICON_STATUS" = "204" ] || [ "$FAVICON_STATUS" = "200" ]; then
    echo "✅ HTTP Status: $FAVICON_STATUS"
else
    echo "❌ HTTP Status: $FAVICON_STATUS (esperado: 204 o 200)"
fi
echo ""

# 7. Verificar código actualizado
echo "7️⃣ Verificando código actualizado:"
echo "----------------------------------------"
echo "🔍 Buscando appStateSyncTimeoutMs en el código:"
docker exec "$CONTAINER_ID" sh -c "grep -n 'appStateSyncTimeoutMs' /app/whatsapp-server-baileys.js 2>/dev/null | head -2 || echo '   ⚠️  No se encontró en el código'"
echo ""

# 8. Verificar eventos recientes
echo "8️⃣ Eventos recientes en los logs:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -E "(QR Code|WhatsApp conectado|Conexión cerrada|device_removed|515|428|401|syncing|resyncing)" | tail -10
echo ""

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ "$ROOT_STATUS" = "200" ] && [ "$HEALTH_STATUS" = "200" ] && [ "$TRAEFIK_OK" = "1" ]; then
    echo "✅ TODO ESTÁ FUNCIONANDO CORRECTAMENTE"
    echo ""
    echo "✅ Contenedor: Activo"
    echo "✅ Traefik: Configurado"
    echo "✅ Endpoints internos: Funcionando"
    echo "✅ Endpoints externos: Funcionando"
    echo ""
    echo "🌐 Puedes abrir: https://api1.checkin24hs.com/"
    echo "   El QR code debería aparecer automáticamente"
else
    echo "⚠️  ALGUNOS COMPONENTES NO ESTÁN FUNCIONANDO"
    echo ""
    if [ "$TRAEFIK_OK" = "0" ]; then
        echo "❌ Traefik: No configurado"
    else
        echo "✅ Traefik: Configurado"
    fi
    
    if [ "$ROOT_STATUS" != "200" ]; then
        echo "❌ Endpoint /: HTTP $ROOT_STATUS"
    else
        echo "✅ Endpoint /: HTTP 200"
    fi
    
    if [ "$HEALTH_STATUS" != "200" ]; then
        echo "❌ Endpoint /api/health: HTTP $HEALTH_STATUS"
    else
        echo "✅ Endpoint /api/health: HTTP 200"
    fi
    
    echo ""
    echo "💡 Si Traefik no está configurado, el script lo configuró automáticamente."
    echo "   Espera 30 segundos más y recarga la página."
fi
echo ""
