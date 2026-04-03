#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN COMPLETA DE WHATSAPP 1"
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

# 2. Verificar logs recientes (últimas 30 líneas)
echo "2️⃣ Verificando logs recientes (últimas 30 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 30 2>&1
echo ""

# 3. Buscar eventos importantes
echo "3️⃣ Buscando eventos importantes:"
echo "----------------------------------------"
echo "📱 QR Codes generados:"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "(QR Code recibido|QR Code generado|QR Code imagen generada)" | tail -3
echo ""
echo "🔄 Reconexiones:"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "(Reconectando|Iniciando reconexión|Socket cerrado)" | tail -5
echo ""
echo "✅ Conexiones exitosas:"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -E "(connected to WA|WhatsApp conectado)" | tail -3
echo ""
echo "❌ Errores recientes:"
docker logs "$CONTAINER_ID" --tail 100 2>&1 | grep -i "error\|fail" | tail -5
echo ""

# 4. Verificar proceso Node.js
echo "4️⃣ Verificando proceso Node.js:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "ps aux 2>/dev/null | grep -E 'node|whatsapp' | grep -v grep || echo '⚠️ ps no disponible, verificando con netstat...'"
docker exec "$CONTAINER_ID" sh -c "netstat -tuln 2>/dev/null | grep 3001 || echo '⚠️ netstat no disponible'"
echo ""

# 5. Verificar Traefik labels
echo "5️⃣ Verificando labels de Traefik:"
echo "----------------------------------------"
SERVICE_NAME=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "⚠️ No se encontró servicio Docker Swarm, verificando contenedor directamente..."
    docker inspect "$CONTAINER_ID" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep -E "traefik|router" || echo "❌ No se encontraron labels de Traefik"
    TRAEFIK_LABELS_FOUND=0
else
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    echo ""
    echo "Labels de Traefik:"
    TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep -E "traefik|router")
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo "❌ No se encontraron labels de Traefik"
        TRAEFIK_LABELS_FOUND=0
    else
        echo "$TRAEFIK_LABELS"
        TRAEFIK_LABELS_FOUND=1
    fi
fi
echo ""

# 6. Probar endpoints internos (desde el contenedor)
echo "6️⃣ Probando endpoints internos (desde el contenedor):"
echo "----------------------------------------"
echo "📊 /api/status:"
docker exec "$CONTAINER_ID" sh -c "wget -qO- http://localhost:3001/api/status 2>/dev/null || (echo '⚠️ wget no disponible, usando node...' && node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log(d))}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\")" 2>&1 | head -5
echo ""
echo "📊 /api/health:"
docker exec "$CONTAINER_ID" sh -c "wget -qO- http://localhost:3001/api/health 2>/dev/null || (echo '⚠️ wget no disponible, usando node...' && node -e \"const http=require('http');http.get('http://localhost:3001/api/health',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log(d))}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\")" 2>&1 | head -5
echo ""
echo "📊 /api/qr:"
docker exec "$CONTAINER_ID" sh -c "wget -qO- http://localhost:3001/api/qr 2>/dev/null || (echo '⚠️ wget no disponible, usando node...' && node -e \"const http=require('http');http.get('http://localhost:3001/api/qr',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log(d.substring(0,200)))}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),2000);\")" 2>&1 | head -5
echo ""

# 7. Probar endpoints externos (vía Traefik)
echo "7️⃣ Probando endpoints externos (vía Traefik):"
echo "----------------------------------------"
echo "🌐 https://api1.checkin24hs.com/api/health:"
curl -s -k -w "\nHTTP Status: %{http_code}\n" https://api1.checkin24hs.com/api/health 2>&1 | head -10
echo ""
echo "🌐 https://api1.checkin24hs.com/api/status:"
curl -s -k -w "\nHTTP Status: %{http_code}\n" https://api1.checkin24hs.com/api/status 2>&1 | head -10
echo ""
echo "🌐 https://api1.checkin24hs.com/api/qr:"
curl -s -k -w "\nHTTP Status: %{http_code}\n" https://api1.checkin24hs.com/api/qr 2>&1 | head -5
echo ""
echo "🌐 https://api1.checkin24hs.com/ (root):"
curl -s -k -w "\nHTTP Status: %{http_code}\n" https://api1.checkin24hs.com/ 2>&1 | head -5
echo ""
echo "🌐 https://api1.checkin24hs.com/favicon.ico:"
curl -s -k -w "\nHTTP Status: %{http_code}\n" -o /dev/null https://api1.checkin24hs.com/favicon.ico 2>&1 | tail -1
echo ""

# 8. Verificar archivos de autenticación
echo "8️⃣ Verificando archivos de autenticación:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "ls -la /app/auth_info_baileys_1/ 2>/dev/null | head -10 || echo '⚠️ Directorio de autenticación no existe o está vacío (esto es normal si no hay sesión guardada)'"
echo ""

# 9. Configurar Traefik si falta
if [ "$TRAEFIK_LABELS_FOUND" = "0" ] && [ -n "$SERVICE_NAME" ]; then
    echo "=========================================="
    echo "🔧 CONFIGURANDO TRAEFIK AUTOMÁTICAMENTE"
    echo "=========================================="
    echo ""
    echo "Agregando labels de Traefik..."
    docker service update \
      --label-add 'traefik.enable=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
      --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
      --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
      "$SERVICE_NAME" 2>&1
    
    echo ""
    echo "✅ Labels de Traefik agregadas"
    echo "⏳ Esperando 15 segundos para que Traefik detecte los cambios..."
    sleep 15
    echo ""
fi

# 10. Resumen
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "✅ Contenedor: $CONTAINER_ID"
echo "✅ Servicio: ${SERVICE_NAME:-'N/A'}"
if [ "$TRAEFIK_LABELS_FOUND" = "0" ] && [ -n "$SERVICE_NAME" ]; then
    echo "✅ Traefik: Configurado automáticamente"
else
    echo "✅ Traefik: ${TRAEFIK_LABELS_FOUND:-'N/A'}"
fi
echo ""
echo "💡 Próximos pasos:"
echo "   1. Si no hay QR code, espera 30-60 segundos"
echo "   2. Si Traefik aún no funciona, ejecuta: ./CONFIGURAR_TRAEFIK_SIMPLE.sh"
echo "   3. Si hay errores de conexión, revisa los logs con: docker logs $CONTAINER_ID --tail 50"
echo ""
