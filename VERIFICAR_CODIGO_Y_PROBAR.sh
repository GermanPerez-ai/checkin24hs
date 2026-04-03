#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO CÓDIGO Y PROBANDO MENSAJES"
echo "=========================================="
echo ""

# Verificar si el código corregido está en el servidor
echo "📋 Verificando si el código corregido está en whatsapp-server.js:"
echo "=========================================="
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Buscando código de detección de cuota..."
    docker exec "$CONTAINER" grep -n "CUOTA DE SUPABASE EXCEDIDA" /app/whatsapp-server.js 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ El código corregido ESTÁ en el servidor"
    else
        echo "❌ El código corregido NO está en el servidor"
        echo "   Necesitas subir whatsapp-server.js desde tu máquina local"
    fi
fi

echo ""
echo "=========================================="
echo "📋 INSTRUCCIONES PARA PROBAR:"
echo "=========================================="
echo ""
echo "1. Envía un mensaje de prueba desde WhatsApp al número conectado"
echo "2. Luego ejecuta este comando para ver los logs en tiempo real:"
echo ""
echo "   CONTAINER=\$(docker ps --filter \"name=whatsapp.1\" --format \"{{.Names}}\" | head -1)"
echo "   docker logs \"\$CONTAINER\" --tail 50 -f"
echo ""
echo "3. Busca mensajes como:"
echo "   - ✅ Mensaje guardado en Supabase"
echo "   - ⚠️ CUOTA DE SUPABASE EXCEDIDA"
echo "   - ❌ Error guardando mensaje"
echo ""




