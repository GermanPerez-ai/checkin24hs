#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO Y CORRIGIENDO ERRORES 404"
echo "=========================================="
echo ""

# 1. Verificar Traefik
echo "1️⃣ Verificando Traefik:"
echo "----------------------------------------"
SERVICE_NAME=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio Docker Swarm"
    exit 1
fi

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
echo ""

# 2. Configurar Traefik si falta
if [ "$TRAEFIK_OK" = "0" ]; then
    echo "=========================================="
    echo "🔧 CONFIGURANDO TRAEFIK"
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
        echo "⏳ Esperando 20 segundos para que Traefik detecte los cambios..."
        sleep 20
        TRAEFIK_OK=1
    else
        echo "❌ Error configurando Traefik"
    fi
    echo ""
fi

# 3. Verificar contenedor
echo "2️⃣ Verificando contenedor:"
echo "----------------------------------------"
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 4. Probar endpoints internos
echo "3️⃣ Probando endpoints internos:"
echo "----------------------------------------"
echo "📊 /api/health:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/health',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log(d))}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\"" 2>&1 | head -3
echo ""

echo "📊 / (root):"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/',(r)=>{console.log('Status:',r.statusCode);let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log('Length:',d.length))}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\"" 2>&1
echo ""

echo "📊 /favicon.ico:"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/favicon.ico',(r)=>{console.log('Status:',r.statusCode)}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\"" 2>&1
echo ""

# 5. Probar endpoints externos
echo "4️⃣ Probando endpoints externos (vía Traefik):"
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
    echo "   Longitud de respuesta: $(echo "$ROOT_BODY" | wc -c) caracteres"
    if echo "$ROOT_BODY" | grep -q "<!DOCTYPE html"; then
        echo "   ✅ Contiene HTML"
    else
        echo "   ⚠️ No contiene HTML"
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

# 6. Verificar logs de Traefik
echo "5️⃣ Verificando logs de Traefik:"
echo "----------------------------------------"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo "📋 Logs recientes relacionados con api1:"
    docker logs "$TRAEFIK_CONTAINER" --tail 30 2>&1 | grep -i "api1\|whatsapp\|404" | tail -5 || echo "   No se encontraron logs relacionados"
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
if [ "$ROOT_STATUS" = "200" ] && [ "$HEALTH_STATUS" = "200" ]; then
    echo "✅ Todos los endpoints funcionan correctamente"
    echo "✅ Traefik está configurado y funcionando"
    echo ""
    echo "🌐 Puedes abrir: https://api1.checkin24hs.com/"
    echo "   El QR code debería aparecer automáticamente"
else
    echo "⚠️ Algunos endpoints no están respondiendo correctamente"
    if [ "$TRAEFIK_OK" = "0" ]; then
        echo "   Traefik fue configurado, espera 30 segundos más y recarga la página"
    else
        echo "   Verifica los logs de Traefik o reinicia el servicio"
    fi
fi
echo ""
