#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNOSTICANDO DESCONEXIÓN Y QR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

echo "1️⃣ Logs completos de los últimos 5 minutos:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 5m 2>&1
echo ""

echo "2️⃣ Buscando eventos de conexión y desconexión:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(WhatsApp conectado|Teléfono conectado|Conexión cerrada|device_removed|401|Reconectando|Iniciando reconexión)" | tail -15
echo ""

echo "3️⃣ Buscando QR codes:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(QR Code recibido|QR Code generado|QR Code imagen)" | tail -10
echo ""

echo "4️⃣ Verificando estado actual del servidor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "node -e \"const http=require('http');http.get('http://localhost:3001/api/status',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>{try{const data=JSON.parse(d);console.log('Estado WhatsApp:',data.whatsapp||data.connected?'Conectado':'Desconectado');console.log('QR disponible:',!!data.qrCode);console.log('Teléfono:',data.phone||'N/A')}catch(e){console.log('Error parseando:',e.message)}})}).on('error',e=>console.error('Error:',e.message));setTimeout(()=>process.exit(0),3000);\"" 2>&1
echo ""

echo "5️⃣ Verificando si hay sesión guardada:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" sh -c "ls -la /app/auth_info_baileys_1/ 2>/dev/null | head -10 || echo '⚠️ Directorio de autenticación no existe o está vacío (esto es normal si no hay sesión)'"
echo ""

echo "6️⃣ Buscando errores recientes:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(Error|error|exception|fail)" | tail -10
echo ""

echo "7️⃣ Verificando si hay intentos de reconexión:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -E "(shouldReconnect|Verificando si debe reconectar|Reconectando)" | tail -10
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si ves 'Conexión cerrada' pero NO ves 'Reconectando...',"
echo "el servidor no está intentando reconectar automáticamente."
echo ""
echo "Si no ves 'QR Code recibido' después de desconectarse,"
echo "el servidor necesita ser reiniciado para generar un nuevo QR."
echo ""
