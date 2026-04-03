#!/bin/bash
set -e

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO DE GUARDADO DE MENSAJES"
echo "=========================================="

CONTAINER=$(docker ps --filter "name=whatsapp" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

echo "=== 1. Verificando código completo de saveMessageToSupabase ==="
docker exec "$CONTAINER" grep -A 35 "async function saveMessageToSupabase" /app/whatsapp-server.js

echo ""
echo "=== 2. Verificando dónde se llama saveMessageToSupabase ==="
docker exec "$CONTAINER" grep -B 2 -A 2 "saveMessageToSupabase" /app/whatsapp-server.js | head -30

echo ""
echo "=== 3. Verificando configuración SAVE_TO_SUPABASE ==="
docker exec "$CONTAINER" grep -i "SAVE_TO_SUPABASE" /app/whatsapp-server.js | head -5

echo ""
echo "=== 4. Últimos logs completos (últimas 50 líneas) ==="
docker logs "$CONTAINER" --tail 50 2>&1 | tail -30

echo ""
echo "=== 5. Buscando cualquier referencia a whatsapp_messages ==="
docker logs "$CONTAINER" --tail 200 2>&1 | grep -i "whatsapp_messages" | tail -10

echo ""
echo "=========================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Ahora:"
echo "  1. Envía un mensaje de prueba a WhatsApp"
echo "  2. Espera 5 segundos"
echo "  3. Ejecuta este comando para ver los logs en tiempo real:"
echo "     docker logs $CONTAINER --tail 20 -f"
echo "  4. Presiona Ctrl+C para detener"
echo ""
echo "💡 Esto mostrará en tiempo real qué ocurre cuando llega un mensaje"


