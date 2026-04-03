#!/bin/bash
# Script para verificar si se creó un chat nuevo después de limpiar

echo "=========================================="
echo "VERIFICAR CHAT NUEVO DESPUÉS DE LIMPIAR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver logs de creación de chat nuevo (últimos 10 minutos)
echo "=== 1. LOGS DE CREACIÓN DE CHAT NUEVO (ÚLTIMOS 10 MIN) ==="
echo ""
echo "Buscando creación de chat nuevo:"
docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Nuevo chat creado|Chat existente encontrado|Chat actualizado" | tail -10
echo ""

echo "Buscando guardado de mensajes:"
docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Mensaje guardado|whatsapp_messages" | tail -10
echo ""

echo "Buscando guardado de interacciones:"
docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Interacción guardada|flor_interactions" | tail -10
echo ""

# 2. Ver errores
echo "=== 2. ERRORES (ÚLTIMOS 10 MIN) ==="
echo ""
ERRORES=$(docker logs $CONTAINER_ID --since 10m 2>&1 | grep -iE "Error|❌|⚠️" | grep -iE "chat|mensaje|supabase" | tail -10)
if [ -n "$ERRORES" ]; then
    echo "❌ Errores encontrados:"
    echo "$ERRORES"
else
    echo "✅ No se encontraron errores relacionados"
fi
echo ""

echo "=========================================="
echo "VERIFICACIÓN EN SUPABASE"
echo "=========================================="
echo ""
echo "Ejecuta en Supabase SQL Editor:"
echo ""
echo "-- Verificar si hay chats nuevos"
echo "SELECT COUNT(*) as total_chats FROM whatsapp_chats;"
echo ""
echo "-- Ver el chat más reciente"
echo "SELECT id, phone, name, last_message, updated_at, created_at"
echo "FROM whatsapp_chats"
echo "ORDER BY created_at DESC"
echo "LIMIT 1;"
echo ""
echo "-- Verificar mensajes nuevos"
echo "SELECT COUNT(*) as total_mensajes FROM whatsapp_messages;"
echo ""
echo "-- Verificar interacciones nuevas"
echo "SELECT COUNT(*) as total_interacciones FROM flor_interactions;"
echo ""
