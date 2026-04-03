#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO PROBLEMA DE CUOTA DE SUPABASE"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 1. Verificar si hay errores de cuota en los logs
echo "1️⃣ Buscando errores de cuota en logs recientes:"
echo "=========================================="
docker logs "$CONTAINER" --tail 200 2>&1 | grep -i "quota\|limit\|exceeded\|egress\|429\|rate limit\|CUOTA" | tail -20
echo ""

# 2. Verificar si hay errores al guardar mensajes
echo "2️⃣ Errores al guardar mensajes:"
echo "=========================================="
docker logs "$CONTAINER" --tail 200 2>&1 | grep -i "error.*guardando\|error.*supabase\|error.*mensaje" | tail -20
echo ""

# 3. Verificar mensajes guardados exitosamente
echo "3️⃣ Mensajes guardados exitosamente (últimos):"
echo "=========================================="
docker logs "$CONTAINER" --tail 200 2>&1 | grep -i "✅.*mensaje\|mensaje guardado\|message saved" | tail -10
echo ""

# 4. Verificar código de detección de cuota
echo "4️⃣ Verificando si el código detecta cuota excedida:"
echo "=========================================="
docker exec "$CONTAINER" grep -n "CUOTA DE SUPABASE EXCEDIDA" /app/whatsapp-server.js 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ El código tiene detección de cuota"
else
    echo "❌ El código NO tiene detección de cuota"
fi
echo ""

# 5. Ver logs en tiempo real mientras se envía un mensaje
echo "5️⃣ Para ver logs en tiempo real:"
echo "=========================================="
echo "Ejecuta este comando y luego envía un mensaje de prueba:"
echo ""
echo "  docker logs \"$CONTAINER\" -f | grep -i \"mensaje\|cuota\|error\|guardando\""
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO:"
echo "=========================================="
echo ""
echo "Si ves errores de 'quota' o 'limit exceeded':"
echo "  - Supabase está rechazando las peticiones por exceder límites"
echo "  - Necesitas actualizar tu plan o esperar al próximo ciclo"
echo ""
echo "Si NO ves errores pero tampoco mensajes guardados:"
echo "  - Los errores pueden estar siendo silenciados"
echo "  - Verifica la configuración de SAVE_TO_SUPABASE"
echo ""
echo "Si ves 'CUOTA DE SUPABASE EXCEDIDA' en los logs:"
echo "  - El código está detectando el problema correctamente"
echo "  - Pero los mensajes no se guardarán hasta resolver la cuota"
echo ""



