#!/bin/bash
# Script para verificar errores al actualizar whatsapp_chats

echo "=========================================="
echo "VERIFICAR ERRORES AL ACTUALIZAR CHATS"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver errores al actualizar whatsapp_chats
echo "=== 1. ERRORES AL ACTUALIZAR whatsapp_chats ==="
echo ""
ERRORES_UPDATE=$(docker logs $CONTAINER_ID --since 2h 2>&1 | grep -iE "Error actualizando whatsapp_chats|Error.*whatsapp_chats.*update|⚠️.*whatsapp_chats")
if [ -n "$ERRORES_UPDATE" ]; then
    echo "❌ Errores encontrados:"
    echo "$ERRORES_UPDATE"
else
    echo "✅ No se encontraron errores explícitos al actualizar chats"
fi
echo ""

# 2. Ver si hay actualizaciones exitosas
echo "=== 2. ACTUALIZACIONES EXITOSAS DE CHATS ==="
echo ""
ACTUALIZACIONES=$(docker logs $CONTAINER_ID --since 2h 2>&1 | grep -iE "Chat actualizado en whatsapp_chats")
if [ -n "$ACTUALIZACIONES" ]; then
    echo "✅ Actualizaciones exitosas encontradas:"
    echo "$ACTUALIZACIONES" | tail -10
    echo "Total: $(echo "$ACTUALIZACIONES" | wc -l)"
else
    echo "❌ NO se encontraron actualizaciones exitosas de chats"
fi
echo ""

# 3. Comparar: mensajes guardados vs chats actualizados
echo "=== 3. COMPARACIÓN: MENSAJES vs CHATS ==="
echo ""
MENSAJES=$(docker logs $CONTAINER_ID --since 2h 2>&1 | grep -c "Mensaje guardado en whatsapp_messages")
CHATS=$(docker logs $CONTAINER_ID --since 2h 2>&1 | grep -c "Chat actualizado en whatsapp_chats")
echo "Mensajes guardados: $MENSAJES"
echo "Chats actualizados: $CHATS"
if [ "$MENSAJES" -gt 0 ] && [ "$CHATS" -eq 0 ]; then
    echo "⚠️ PROBLEMA DETECTADO: Se guardan mensajes pero NO se actualizan chats"
elif [ "$MENSAJES" -gt "$CHATS" ]; then
    echo "⚠️ PROBLEMA DETECTADO: Se guardan más mensajes que chats actualizados"
else
    echo "✅ La proporción parece correcta"
fi
echo ""

# 4. Ver logs completos alrededor de mensajes guardados
echo "=== 4. LOGS COMPLETOS (últimos mensajes guardados) ==="
echo ""
echo "Últimos 5 mensajes guardados con contexto:"
docker logs $CONTAINER_ID --since 2h 2>&1 | grep -A 5 -B 5 "Mensaje guardado en whatsapp_messages" | tail -30
echo ""

# 5. Verificar si hay errores de Supabase
echo "=== 5. ERRORES DE SUPABASE ==="
echo ""
ERRORES_SUPABASE=$(docker logs $CONTAINER_ID --since 2h 2>&1 | grep -iE "Supabase.*error|Invalid API key|quota|limit|exceeded|403|429")
if [ -n "$ERRORES_SUPABASE" ]; then
    echo "⚠️ Errores relacionados con Supabase:"
    echo "$ERRORES_SUPABASE" | tail -10
else
    echo "✅ No se encontraron errores explícitos de Supabase"
fi
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "Si ves 'Mensaje guardado' pero NO ves 'Chat actualizado',"
echo "significa que la actualización de whatsapp_chats está fallando."
echo ""
echo "Posibles causas:"
echo "1. Supabase bloqueando actualizaciones (cuota excedida)"
echo "2. Error silencioso en la actualización"
echo "3. El código de actualización no se está ejecutando"
echo ""
