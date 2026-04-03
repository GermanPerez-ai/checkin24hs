#!/bin/bash
# Script para verificar si los mensajes se están guardando en Supabase

echo "=========================================="
echo "VERIFICAR GUARDADO DE MENSAJES EN CHAT"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar logs de guardado de mensajes
echo "=== PASO 1: LOGS DE GUARDADO DE MENSAJES ==="
echo ""
echo "Últimos mensajes guardados:"
docker logs $CONTAINER_ID --tail 200 | grep -iE "Mensaje guardado|Chat actualizado|obtenerOcrearChatId|Nuevo chat creado" | tail -20
echo ""

# 2. Verificar errores al guardar
echo "=== PASO 2: ERRORES AL GUARDAR ==="
echo ""
ERRORES=$(docker logs $CONTAINER_ID --tail 200 | grep -iE "Error guardando|No se pudo obtener/crear chat_id|Error actualizando whatsapp_chats" | tail -10)
if [ -n "$ERRORES" ]; then
    echo "$ERRORES"
else
    echo "✅ No se encontraron errores al guardar mensajes"
fi
echo ""

# 3. Verificar función obtenerOcrearChatId
echo "=== PASO 3: VERIFICAR FUNCIÓN obtenerOcrearChatId ==="
echo ""
echo "Buscando función obtenerOcrearChatId en el código:"
docker exec $CONTAINER_ID grep -A 5 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | head -10
echo ""

# 4. Verificar si está priorizando whatsapp_chats
echo "=== PASO 4: VERIFICAR PRIORIDAD DE whatsapp_chats ==="
echo ""
PRIORIDAD=$(docker exec $CONTAINER_ID grep -A 10 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -i "whatsapp_chats" | head -3)
if [ -n "$PRIORIDAD" ]; then
    echo "✅ La función menciona whatsapp_chats:"
    echo "$PRIORIDAD"
else
    echo "⚠️ No se encontró referencia a whatsapp_chats en la función"
fi
echo ""

# 5. Verificar mensajes recibidos recientes
echo "=== PASO 5: MENSAJES RECIBIDOS RECIENTES ==="
echo ""
MENSAJES=$(docker logs $CONTAINER_ID --tail 100 | grep -i "📱 Mensaje recibido" | tail -5)
if [ -n "$MENSAJES" ]; then
    echo "Mensajes recibidos:"
    echo "$MENSAJES"
else
    echo "⚠️ No se encontraron mensajes recibidos en los logs recientes"
fi
echo ""

echo "=========================================="
echo "DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si los mensajes no aparecen en el dashboard:"
echo "1. Verifica que no haya errores al guardar (ver arriba)"
echo "2. Verifica que la función obtenerOcrearChatId esté priorizando whatsapp_chats"
echo "3. Verifica en Supabase directamente si los mensajes se están guardando"
echo "4. Verifica que el dashboard esté consultando la tabla correcta (whatsapp_chats)"
echo ""
