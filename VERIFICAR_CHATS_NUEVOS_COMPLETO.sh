#!/bin/bash
# Script para verificar si los chats nuevos se están guardando

echo "=========================================="
echo "VERIFICAR CHATS NUEVOS"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor de WhatsApp corriendo"
    echo "   El servicio puede estar reiniciándose"
    CONTAINER_ID=$(docker ps -a | grep whatsapp | grep -v nginx | head -1 | awk '{print $1}')
    if [ -n "$CONTAINER_ID" ]; then
        echo "   Usando último contenedor: $CONTAINER_ID"
    fi
else
    echo "Contenedor: $CONTAINER_ID"
fi
echo ""

# 1. Verificar logs de guardado de chats (últimas 2 horas)
echo "=== PASO 1: LOGS DE GUARDADO DE CHATS (ÚLTIMAS 2 HORAS) ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Buscando logs de guardado de chats nuevos:"
    docker logs $CONTAINER_ID --since 2h 2>&1 | grep -iE "Chat existente encontrado|Nuevo chat creado|Mensaje guardado|whatsapp_chats" | tail -20
    echo ""
    
    echo "Buscando errores al guardar chats:"
    ERRORES_CHATS=$(docker logs $CONTAINER_ID --since 2h 2>&1 | grep -iE "Error.*chat|Error.*whatsapp_chats|No se pudo obtener/crear chat" | tail -10)
    if [ -n "$ERRORES_CHATS" ]; then
        echo "❌ Errores encontrados:"
        echo "$ERRORES_CHATS"
    else
        echo "✅ No se encontraron errores al guardar chats"
    fi
    echo ""
else
    echo "⚠️ No se puede verificar logs (contenedor no encontrado)"
    echo ""
fi

# 2. Verificar función obtenerOcrearChatId
echo "=== PASO 2: VERIFICAR CÓDIGO DE CREACIÓN DE CHATS ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Buscando función obtenerOcrearChatId:"
    docker exec $CONTAINER_ID grep -A 5 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | head -10
    echo ""
    
    echo "Verificando que crea en whatsapp_chats:"
    docker exec $CONTAINER_ID grep -A 3 "from('whatsapp_chats')" /app/whatsapp-server-baileys.js | head -10
    echo ""
else
    echo "⚠️ No se puede verificar código (contenedor no encontrado)"
    echo ""
fi

# 3. Verificar variables de entorno
echo "=== PASO 3: VARIABLES DE ENTORNO ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Variables relacionadas con Supabase:"
    docker exec $CONTAINER_ID env | grep -E "(SUPABASE|SAVE_TO_SUPABASE)" | grep -v "PASSWORD\|SECRET"
    echo ""
else
    echo "⚠️ No se puede verificar variables (contenedor no encontrado)"
    echo ""
fi

# 4. Verificar mensajes procesados recientemente
echo "=== PASO 4: MENSAJES PROCESADOS RECIENTEMENTE ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Últimos mensajes procesados (últimas 2 horas):"
    docker logs $CONTAINER_ID --since 2h 2>&1 | grep -iE "Mensaje recibido|Mensaje guardado|procesando.*mensaje" | tail -10
    echo ""
else
    echo "⚠️ No se puede verificar mensajes (contenedor no encontrado)"
    echo ""
fi

echo "=========================================="
echo "VERIFICACIÓN EN SUPABASE"
echo "=========================================="
echo ""
echo "Para verificar directamente en Supabase, ejecuta estas consultas SQL:"
echo ""
echo "-- 1. Verificar chats nuevos (últimas 24 horas)"
echo "SELECT"
echo "    id,"
echo "    phone,"
echo "    name,"
echo "    last_message,"
echo "    last_message_time,"
echo "    updated_at,"
echo "    created_at"
echo "FROM whatsapp_chats"
echo "WHERE updated_at >= NOW() - INTERVAL '24 hours'"
echo "ORDER BY updated_at DESC;"
echo ""
echo "-- 2. Verificar mensajes nuevos (últimas 24 horas)"
echo "SELECT"
echo "    id,"
echo "    phone,"
echo "    LEFT(message, 50) as mensaje_preview,"
echo "    is_from_me,"
echo "    created_at"
echo "FROM whatsapp_messages"
echo "WHERE created_at >= NOW() - INTERVAL '24 hours'"
echo "ORDER BY created_at DESC"
echo "LIMIT 20;"
echo ""
echo "-- 3. Contar chats totales vs chats nuevos"
echo "SELECT"
echo "    COUNT(*) as total_chats,"
echo "    COUNT(*) FILTER (WHERE updated_at >= NOW() - INTERVAL '24 hours') as chats_nuevos_24h,"
echo "    COUNT(*) FILTER (WHERE updated_at >= NOW() - INTERVAL '7 days') as chats_nuevos_7d"
echo "FROM whatsapp_chats;"
echo ""
