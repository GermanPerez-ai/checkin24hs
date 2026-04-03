#!/bin/bash

echo "=========================================="
echo "🔍 REVISANDO ERROR 'VUELVA A INTENTAR MÁS TARDE'"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp.1" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Logs completos de los últimos 5 minutos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | tail -50
echo ""

echo "2️⃣ Eventos de QR code y escaneo:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code|QR escaneado|pairing|logging in)" | tail -15
echo ""

echo "3️⃣ Intentos de conexión:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(connected to WA|opened connection|WhatsApp conectado)" | tail -10
echo ""

echo "4️⃣ Errores o rechazos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Error|error|rejected|denied|failed|timeout|expired|rate limit|too many)" | tail -15
echo ""

echo "5️⃣ Estado actual del servidor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado WhatsApp:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR disponible:',!!data.qrCode);console.log('Teléfono:',data.phone||'N/A')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "6️⃣ Verificando si hay rate limiting o bloqueos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -E "(429|rate limit|too many|blocked|banned|temporal)" | tail -10
echo ""

echo "7️⃣ Timeline de eventos recientes:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code|pairing|logging in|connected|Error|error|rejected)" | tail -20
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "El mensaje 'vuelva a intentar más tarde' puede ser por:"
echo "  1. Demasiados intentos de conexión en poco tiempo"
echo "  2. WhatsApp está bloqueando temporalmente por seguridad"
echo "  3. El QR code expiró muy rápido"
echo "  4. Hay un problema de red o conectividad"
echo ""
echo "Si ves errores de 'rate limit' o '429', WhatsApp está bloqueando temporalmente."
echo "En ese caso, espera 10-15 minutos antes de intentar de nuevo."
echo ""
