#!/bin/bash

echo "=========================================="
echo "🔍 REVISANDO ERROR DE CONEXIÓN DEL TELÉFONO"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp.1" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Logs completos de los últimos 5 minutos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | tail -50
echo ""

echo "2️⃣ Eventos de QR code:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code|QR code|qr)" | tail -10
echo ""

echo "3️⃣ Intentos de conexión:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(pairing|logging in|connected to WA|opened connection)" | tail -10
echo ""

echo "4️⃣ Errores recientes:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Error|error|failed|timeout|expired)" | tail -10
echo ""

echo "5️⃣ Estado actual del servidor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado WhatsApp:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR disponible:',!!data.qrCode);console.log('Teléfono:',data.phone||'N/A');console.log('Última actualización:',data.timestamp||'N/A')}catch(e){console.log('Error:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "6️⃣ Verificando si el QR code expiró:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR.*expired|QR.*timeout|qrTimeout)" | tail -5
echo ""

echo "7️⃣ Verificando conectividad del servidor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo '⚠️ netstat/ss no disponible'"
echo ""

echo "8️⃣ Verificando si hay sesión guardada:"
echo "----------------------------------------"
FILE_COUNT=$(docker exec "$CONTAINER_ID" sh -c "find /app/auth_info_baileys_1 -type f 2>/dev/null | wc -l")
if [ "$FILE_COUNT" -eq "0" ]; then
    echo "✅ No hay sesión guardada (correcto, esperando QR)"
else
    echo "⚠️  Hay $FILE_COUNT archivo(s) de sesión guardados"
    docker exec "$CONTAINER_ID" sh -c "find /app/auth_info_baileys_1 -type f 2>/dev/null | head -5"
fi
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si el QR code expiró, el servidor generará uno nuevo automáticamente."
echo "Si hay errores de conexión, pueden ser por:"
echo "  - Problemas de red"
echo "  - QR code expirado"
echo "  - Múltiples intentos de conexión simultáneos"
echo "  - Sesión conflictiva en WhatsApp"
echo ""
